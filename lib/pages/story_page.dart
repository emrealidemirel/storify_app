import 'package:flutter_story_app/widgets/ai_consent_dialog.dart';
import 'package:flutter_story_app/widgets/story_report_dialog.dart';
import 'package:flutter_story_app/widgets/brand_wordmark.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:flutter_story_app/widgets/choice_button.dart';
import 'package:flutter_story_app/widgets/loading_indicator.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';

class StoryPage extends StatefulWidget {
  final bool continueFromLast;
  final String? theme;
  final String? gender;
  const StoryPage({
    super.key,
    required this.continueFromLast,
    this.theme,
    this.gender,
  });

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final ScrollController _scrollController = ScrollController();
  String? _lastChoice;
  List<String>? _lastStoryTexts;

  void _returnToHome() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil(Routes.home, (route) => false);
    }
  }

  Future<bool> _consent() async {
    final owner = context.read<StoryCubit>().aiUserId();
    if (owner == null) return true;
    try {
      return await ensureAIConsent(context, owner);
    } catch (_) {
      return false;
    }
  }

  Future<void> _retryStory() async {
    if (!await _consent() || !mounted) return;
    final storyCubit = context.read<StoryCubit>();
    if (_lastChoice != null && _lastStoryTexts != null) {
      storyCubit.continueStory(_lastChoice!, _lastStoryTexts!);
    } else if (widget.continueFromLast) {
      storyCubit.continueToLastStory();
    } else {
      storyCubit.startNewStory(theme: widget.theme, gender: widget.gender);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!widget.continueFromLast && !await _consent()) {
        if (mounted) _returnToHome();
        return;
      }
      if (!mounted) return;
      final storyCubit = context.read<StoryCubit>();
      if (widget.continueFromLast) {
        storyCubit.continueToLastStory();
      } else {
        storyCubit.startNewStory(theme: widget.theme, gender: widget.gender);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storyCubit = context.read<StoryCubit>();
    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'back_to_home'.tr(),
          icon: const Icon(Icons.arrow_back),
          onPressed: _returnToHome,
        ),
        title: const BrandWordmark(),
      ),
      body: BlocConsumer<StoryCubit, StoryState>(
        listener: (context, state) {
          if (state is StoryLoaded) _scrollToBottom();
        },
        builder: (context, state) {
          final isLoading = state is StoryLoading;
          final story =
              state is StoryLoaded
                  ? state
                  : state is StoryLoading
                  ? state.previousStory
                  : null;
          if (story != null) {
            return Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (story.isGuest) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: const Icon(
                            Icons.auto_stories_outlined,
                            size: 18,
                          ),
                          label: Text('guest_story_badge'.tr()),
                        ),
                      ),
                      if (story.title != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          story.title!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                    for (final text in story.storyText)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          text,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.8),
                        ),
                      ),
                    if (!story.isGuest)
                      TextButton.icon(
                        icon: const Icon(Icons.flag_outlined),
                        label: Text('report_story'.tr()),
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  final uid = storyCubit.aiUserId();
                                  if (uid == null) return;
                                  final sent = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (_) => StoryReportDialog(
                                          userId: uid,
                                          passages: List.of(story.storyText),
                                          choices: List.of(story.choices),
                                        ),
                                  );
                                  if (!context.mounted || sent != true) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('report_sent'.tr())),
                                  );
                                },
                      ),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (story.isComplete) ...[
                      Text(
                        (story.isGuest
                                ? 'guest_story_finished'
                                : 'ai_story_finished')
                            .tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      if (story.isGuest)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                isLoading
                                    ? null
                                    : () => storyCubit.startNewStory(
                                      theme:
                                          widget.theme ?? storyCubit.storyTheme,
                                      gender:
                                          widget.gender ?? storyCubit.gender,
                                    ),
                            icon: const Icon(Icons.replay_rounded),
                            label: Text('guest_story_restart'.tr()),
                          ),
                        ),
                    ],
                    for (final choice in story.choices)
                      ChoiceButton(
                        buttonText: choice,
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  if (!await _consent() || !mounted) return;
                                  _lastChoice = choice;
                                  _lastStoryTexts = List<String>.from(
                                    story.storyText,
                                  );
                                  storyCubit.continueStory(
                                    choice,
                                    story.storyText,
                                  );
                                },
                      ),
                  ],
                ),
                if (isLoading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: const Padding(
                            padding: EdgeInsets.all(18),
                            child: SizedBox.square(
                              dimension: 28,
                              child: LoadingIndicator(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          } else if (isLoading || state is StoryInitial) {
            return const LoadingIndicator();
          } else {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (state is StoryError)
                          ? state.errorMessage
                          : "story_error_text".tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 3.h),
                    if (state is! StoryError || state.canRetry) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _retryStory,
                          icon: const Icon(Icons.refresh),
                          label: Text('retry'.tr()),
                        ),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: _returnToHome,
                      icon: const Icon(Icons.home_outlined),
                      label: Text('back_to_home'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
