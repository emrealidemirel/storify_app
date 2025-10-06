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
  const StoryLoading();

  @override
  List<Object> get props => [];
}

final class StoryLoaded extends StoryState {
  final List<String> storyText;
  final List<String> choices;
  const StoryLoaded({required this.storyText, required this.choices});

  @override
  List<Object> get props => [storyText, choices];
}

final class StoryError extends StoryState {
  final String errorMessage;

  const StoryError({required this.errorMessage});
  @override
  List<Object> get props => [errorMessage];
}