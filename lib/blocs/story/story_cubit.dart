import 'package:flutter_story_app/services/content_safety_service.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/models/story_model.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/repositories/guest_story_repository.dart';
import 'package:flutter_story_app/services/preferences_service.dart';

class StoryCubit extends Cubit<StoryState> {
  final StoryRepository storyRepository;
  final GuestStoryRepository guestRepository;
  final String languageCode;

  /// Null means no registered account: use authored stories, never the API.
  final String? Function() aiUserId;
  bool get isGuest => aiUserId() == null;
  String storyTheme = 'theme_horror';
  String gender = 'gender_male';
  List<String> stories = [];
  List<String> _offeredChoices = [];
  GuestStory? _guestStory;
  String _chapter = 'start';
  String? _sessionOwner;
  bool _busy = false;
  int _request = 0;

  StoryCubit({
    required this.storyRepository,
    required this.languageCode,
    String? Function()? aiUserId,
    GuestStoryRepository? guestRepository,
  }) : aiUserId = aiUserId ?? (() => null),
       guestRepository = guestRepository ?? GuestStoryRepository(),
       super(const StoryInitial());

  bool _current(int request, String? owner) =>
      !isClosed && request == _request && aiUserId() == owner;

  Future<void> startNewStory({String? theme, String? gender}) async {
    if (_busy) return;
    _busy = true;
    final request = ++_request;
    final owner = aiUserId();
    _sessionOwner = owner;
    _guestStory = null;
    try {
      emit(const StoryLoading());
      if (theme != null && theme.isNotEmpty) storyTheme = theme;
      if (gender != null && gender.isNotEmpty) this.gender = gender;
      final language =
          await PreferencesService.getLanguageCode() ?? languageCode;
      if (!_current(request, owner)) return;
      if (owner == null) {
        final guest = await guestRepository.load(
          storyTheme,
          language,
          this.gender,
        );
        if (!_current(request, owner)) return;
        _guestStory = guest;
        _chapter = 'start';
        stories = [guest.chapters[_chapter]!.text];
        _emitGuest();
        return;
      }
      if (!_configured()) return;
      final story = await storyRepository.startNewStory(
        storyTheme.tr(),
        this.gender.tr(),
        language,
      );
      if (!_current(request, owner)) return;
      if (story == null) {
        emit(StoryError(errorMessage: 'story_error_text'.tr()));
        return;
      }
      stories = [story.text];
      _offeredChoices = List.of(story.choices);
      await _save(story, owner);
      if (_current(request, owner)) {
        emit(StoryLoaded(storyText: List.of(stories), choices: story.choices));
      }
    } catch (error) {
      if (_current(request, owner)) _emitRequestError(error);
    } finally {
      if (request == _request) _busy = false;
    }
  }

  Future<void> continueStory(String choice, List<String> storyTexts) async {
    if (_busy) return;
    _busy = true;
    final request = ++_request;
    final owner = aiUserId();
    try {
      // Do not turn a guest session into an AI request after an account change.
      if (_guestStory != null) {
        if (owner != null) {
          emit(
            StoryError(
              errorMessage: 'story_session_changed'.tr(),
              canRetry: false,
            ),
          );
          return;
        }
        final options = _guestStory!.chapters[_chapter]!.choices;
        final matches = options.where((option) => option.label == choice);
        if (matches.isEmpty) return;
        _chapter = matches.first.next;
        stories = [...stories, _guestStory!.chapters[_chapter]!.text];
        _emitGuest();
        return;
      }
      if (owner == null || (_sessionOwner != null && owner != _sessionOwner)) {
        emit(
          StoryError(
            errorMessage: 'story_session_changed'.tr(),
            canRetry: false,
          ),
        );
        return;
      }
      if (storyTexts.length >= 30) {
        emit(StoryLoaded(storyText: List.of(storyTexts), choices: const []));
        return;
      }
      final previous = state;
      emit(
        StoryLoading(previousStory: previous is StoryLoaded ? previous : null),
      );
      if (!_configured()) return;
      final language =
          await PreferencesService.getLanguageCode() ?? languageCode;
      if (!_current(request, owner)) return;
      final story = await storyRepository.continueStory(
        storyTexts.join('\n'),
        choice,
        storyTheme.tr(),
        gender.tr(),
        language,
        previousChoices: List.of(_offeredChoices),
      );
      if (!_current(request, owner)) return;
      if (story == null) {
        emit(StoryError(errorMessage: 'story_error_text'.tr()));
        return;
      }
      stories = [...storyTexts, story.text];
      final nextChoices = stories.length >= 30 ? <String>[] : story.choices;
      _offeredChoices = {..._offeredChoices, ...story.choices}.toList();
      await _save(Story(text: story.text, choices: nextChoices), owner);
      if (_current(request, owner)) {
        emit(StoryLoaded(storyText: List.of(stories), choices: nextChoices));
      }
    } catch (error) {
      if (_current(request, owner)) _emitRequestError(error);
    } finally {
      if (request == _request) _busy = false;
    }
  }

  void _emitGuest() {
    emit(
      StoryLoaded(
        storyText: List.of(stories),
        choices:
            _guestStory!.chapters[_chapter]!.choices
                .map((c) => c.label)
                .toList(),
        isGuest: true,
        title: _guestStory!.title,
      ),
    );
  }

  bool _configured() {
    if (storyRepository.isConfigured) return true;
    emit(
      StoryError(
        errorMessage: 'story_configuration_error'.tr(),
        canRetry: false,
      ),
    );
    return false;
  }

  Future<void> _save(Story story, String owner) async {
    await PreferencesService.saveStoryOwner(owner);
    await PreferencesService.saveLastStories(stories);
    await PreferencesService.saveLastChoices(story.choices);
    await PreferencesService.saveOfferedChoices(_offeredChoices);
    await PreferencesService.saveLastStorySelection(
      theme: storyTheme,
      gender: gender,
    );
  }

  void _emitRequestError(Object error) {
    // Never display or log raw provider messages: they may contain credentials.
    if (error is UnsafeStoryException) {
      emit(StoryError(errorMessage: 'story_unsafe'.tr()));
    } else if (error is OpenAIRateLimitError) {
      final details = error.data?.error;
      final quotaExceeded =
          details?.type == 'insufficient_quota' ||
          details?.code == 'insufficient_quota' ||
          details?.code == 'billing_hard_limit_reached' ||
          const {
            'credit_balance_exhausted',
            'organization_spend_limit_exceeded',
            'project_spend_limit_exceeded',
            'organization_usage_limit_exceeded',
          }.contains(details?.code);
      final messageKey =
          details?.code == 'credit_balance_exhausted'
              ? 'story_credit_error'
              : quotaExceeded
              ? 'story_quota_error'
              : 'story_rate_limit_error';
      emit(StoryError(errorMessage: messageKey.tr(), canRetry: !quotaExceeded));
    } else if (error is OpenAIAuthError || error is MissingTokenException) {
      emit(
        StoryError(
          errorMessage: 'story_configuration_error'.tr(),
          canRetry: false,
        ),
      );
    } else if (error is OpenAIServerError) {
      emit(StoryError(errorMessage: 'story_service_error'.tr()));
    } else if (error is FormatException) {
      emit(StoryError(errorMessage: 'story_response_error'.tr()));
    } else {
      emit(StoryError(errorMessage: 'story_error_text'.tr()));
    }
  }

  Future<void> continueToLastStory() => _restore(showError: true);
  Future<void> checkForSavedStory() => _restore(showError: false);

  Future<void> _restore({required bool showError}) async {
    final owner = aiUserId();
    if (owner == null || _busy) return;
    final request = ++_request;
    try {
      final savedOwner = await PreferencesService.getStoryOwner();
      final savedStories = await PreferencesService.getLastStories();
      final choices = await PreferencesService.getLastChoices();
      final offeredChoices = await PreferencesService.getOfferedChoices();
      final savedTheme = await PreferencesService.getLastStoryTheme();
      final savedGender = await PreferencesService.getLastStoryGender();
      if (!_current(request, owner)) return;
      if (savedOwner == owner &&
          savedStories != null &&
          savedStories.isNotEmpty &&
          choices != null) {
        _guestStory = null;
        _sessionOwner = owner;
        stories = savedStories;
        // Older saves only contain the choices for their latest passage.
        _offeredChoices = {...?offeredChoices, ...choices}.toList();
        storyTheme = savedTheme ?? storyTheme;
        gender = savedGender ?? gender;
        emit(StoryLoaded(storyText: List.of(stories), choices: choices));
      } else {
        stories = [];
        _offeredChoices = [];
        emit(
          showError
              ? StoryError(errorMessage: 'story_save_error_text'.tr())
              : const StoryInitial(),
        );
      }
    } catch (_) {
      if (_current(request, owner)) {
        emit(StoryError(errorMessage: 'story_error_text'.tr()));
      }
    }
  }

  void clearSession() {
    ++_request;
    _busy = false;
    _guestStory = null;
    _sessionOwner = null;
    stories = [];
    _offeredChoices = [];
    if (!isClosed) emit(const StoryInitial());
  }

  Future<bool> resetStory() async {
    ++_request;
    _busy = false;
    _guestStory = null;
    _sessionOwner = null;
    stories = [];
    _offeredChoices = [];
    emit(const StoryLoading());
    try {
      await PreferencesService.clearStoryData();
      if (!isClosed) emit(const StoryInitial());
      return true;
    } catch (_) {
      if (!isClosed) emit(StoryError(errorMessage: 'story_error_text'.tr()));
      return false;
    }
  }
}
