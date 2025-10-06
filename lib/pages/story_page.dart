import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/widgets/choice_button.dart';
import 'package:flutter_story_app/widgets/loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';

class StoryPage extends StatefulWidget {
  final bool continueFromLast;
  const StoryPage({super.key, required this.continueFromLast});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storyCubit = context.read<StoryCubit>();
      if (widget.continueFromLast) {
        storyCubit.continueToLastStory();
      } else {
        storyCubit.startNewStory();
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
        title: Text(
          "app_title".tr(),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: BlocBuilder<StoryCubit, StoryState>(
        builder: (context, state) {
          if (state is StoryLoading) {
            return const LoadingIndicator();
          } else if (state is StoryLoaded) {
            _scrollToBottom();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: state.storyText.length,
                      separatorBuilder:
                          (context, index) => SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final isLast = state.storyText.length == index + 1;
                        return Text(
                          state.storyText[index],
                          style: GoogleFonts.poppins(
                            fontSize: isLast ? 17.sp : 16.sp,
                            fontWeight: isLast ? FontWeight.w400 : FontWeight.w300,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 25.h,
                    child: Column(
                      children:
                          state.choices
                              .map(
                                (choice) => ChoiceButton(
                                  buttonText: choice,
                                  onPressed: () {
                                    storyCubit.continueStory(
                                      choice,
                                      state.storyText,
                                    );
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                (state is StoryError)
                    ? state.errorMessage
                    : "story_error_text".tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.deepPurple.shade400,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
        },
      ),
    );
  }
}