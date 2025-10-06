import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_state.dart';
import 'package:flutter_story_app/pages/story_page.dart';
import 'package:flutter_story_app/pages/theme_selection_page.dart';
import 'package:flutter_story_app/widgets/app_drawer.dart';
import 'package:flutter_story_app/widgets/primary_button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final storyCubit = context.read<StoryCubit>();
    storyCubit.checkForSavedStory();

    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          onRestartStory: () {
            storyCubit.startNewStory(theme: '', gender: '');
          },
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 7.h,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        iconSize: 3.2.h,
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "app_title".tr(),
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 1.2.h),
              Text(
                "story_intro_text".tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: Image.asset(
                  'assets/images/story-intro.jpg',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 4.h),
              PrimaryButton(
                buttonText: "start_story_button".tr(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ThemeSelectionPage(
                            onSelectionDone: (theme, gender) {
                              storyCubit.startNewStory(
                                theme: theme.toLowerCase(),
                                gender: gender,
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const StoryPage(
                                        continueFromLast: false,
                                      ),
                                ),
                              );
                            },
                          ),
                    ),
                  );
                },
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState is AuthAuthenticated &&
                      !authState.user.isAnonymous) {
                    return BlocBuilder<StoryCubit, StoryState>(
                      builder: (context, storyState) {
                        if (storyState is StoryLoaded &&
                            storyState.storyText.isNotEmpty) {
                          return PrimaryButton(
                            buttonColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.deepPurple.shade400,
                            buttonText: "continue_story_button".tr(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const StoryPage(
                                        continueFromLast: true,
                                      ),
                                ),
                              );
                            },
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
