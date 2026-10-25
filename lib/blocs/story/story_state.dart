import 'package:equatable/equatable.dart';

abstract class StoryState extends Equatable {
  const StoryState();

  @override
  List<Object> get props => [];
}

final class StoryInitial extends StoryState {
  const StoryInitial();

  @override
  List<Object> get props => [];
}

final class StoryLoading extends StoryState {
  final StoryLoaded? previousStory;
  const StoryLoading({this.previousStory});

  @override
  List<Object> get props => [if (previousStory != null) previousStory!];
}

final class StoryLoaded extends StoryState {
  final List<String> storyText;
  final List<String> choices;
  final bool isGuest;
  final String? title;
  bool get isComplete => choices.isEmpty;
  const StoryLoaded({
    required this.storyText,
    required this.choices,
    this.isGuest = false,
    this.title,
  });

  @override
  List<Object> get props => [storyText, choices, isGuest, title ?? ""];
}

final class StoryError extends StoryState {
  final String errorMessage;
  final bool canRetry;

  const StoryError({required this.errorMessage, this.canRetry = true});

  @override
  List<Object> get props => [errorMessage, canRetry];
}
