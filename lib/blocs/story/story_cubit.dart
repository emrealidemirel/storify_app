import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/services/preferences_service.dart';

class StoryCubit extends Cubit<StoryState> {
  final StoryRepository storyRepository;
  final String languageCode;

  String storyTheme = "theme_horror".tr();
  String gender = "gender_male".tr();

  StoryCubit({required this.storyRepository, required this.languageCode}) : super(const StoryLoading());

  List<String> stories = [];

  void startNewStory({String? theme, String? gender}) async {
    try {
      emit(StoryLoading());

      if (theme != null) storyTheme = theme;
      if (gender != null) this.gender = gender;

      final languageCode = await PreferencesService.getLanguageCode() ?? "en";

      final story = await storyRepository.startNewStory(
        storyTheme,
        this.gender,
        languageCode,
      );

      if (story != null) {
        stories = [story.text];
        await PreferencesService.saveLastStoryText(story.text);
        await PreferencesService.saveLastChoices(story.choices);
        emit(StoryLoaded(storyText: stories, choices: story.choices));
      } else {
        emit(StoryError(errorMessage: "story_error_text".tr()));
      }
    } catch (e) {
      emit(StoryError(errorMessage: e.toString()));
    }
  }

  void continueStory(String choice, List<String> storyTexts) async {
    try {
      emit(StoryLoading());

      final languageCode = await PreferencesService.getLanguageCode() ?? "en";

      final nextStory = await storyRepository.continueStory(
        storyTexts.last,
        choice,
        storyTheme,
        gender,
        languageCode,
      );
      

      if (nextStory != null) {
        stories = List<String>.from(storyTexts)..add(nextStory.text);
        await PreferencesService.saveLastStoryText(nextStory.text);
        await PreferencesService.saveLastChoices(nextStory.choices);
        emit(StoryLoaded(storyText: stories, choices: nextStory.choices));
      } else {
        emit(StoryError(errorMessage: "story_error_text".tr()));
      }
    } catch (e) {
      emit(StoryError(errorMessage: e.toString()));
    }
  }

  Future<void> continueToLastStory() async {
    final lastStoryText = await PreferencesService.getLastStoryText();
    final lastChoices = await PreferencesService.getLastChoices();

    if (lastStoryText != null && lastChoices != null && lastChoices.isNotEmpty) {
      stories = [lastStoryText];
      emit(StoryLoaded(storyText: stories, choices: lastChoices));
    } else {
      emit(StoryError(errorMessage: "story_save_error_text".tr()));
    }
  }

  void checkForSavedStory() async {
    final lastStoryText = await PreferencesService.getLastStoryText();
    final lastChoices = await PreferencesService.getLastChoices();

    if (lastStoryText != null && lastChoices != null && lastChoices.isNotEmpty) {
      stories = [lastStoryText];
      emit(StoryLoaded(storyText: stories, choices: lastChoices));
    }
  }

  Future<void> resetStory(AuthState authState) async {
  emit(StoryLoading());
  try {
    if (authState is AuthAuthenticated) {
      if (authState.user.isAnonymous) {
        await PreferencesService.clearStoryData();
      } else {
        await PreferencesService.clearStoryData();
      }
    } else {
      await PreferencesService.clearStoryData();
    }
    emit(StoryInitial());
  } catch (e) {
    emit(StoryError(errorMessage: 'Hikaye sıfırlanamadı.'));
  }
}

}