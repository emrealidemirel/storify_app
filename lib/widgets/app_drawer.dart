import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/theme/theme_cubit.dart';
import 'package:flutter_story_app/contants/routes.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onRestartStory;

  const AppDrawer({super.key, this.onRestartStory});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final isDark = context.watch<ThemeCubit>().state.themeMode == ThemeMode.dark;

    final authState = context.watch<AuthCubit>().state;
    final isLoggedIn = authState is AuthAuthenticated;
    final user = isLoggedIn ? authState.user : null;
    final isGuest = user?.isAnonymous ?? true;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    isLoggedIn
                        ? (isGuest
                            ? 'user'.tr()
                            : (user?.displayName?.isNotEmpty == true
                                ? user!.displayName!
                                : (user?.email?.split('@').first ??
                                    'user'.tr())))
                        : '',
                  ),
                  accountEmail: Text(isLoggedIn ? (user?.email ?? '') : ''),
                  currentAccountPicture: CircleAvatar(
                    radius: 9.w,
                    backgroundColor: Colors.white,
                    backgroundImage: isLoggedIn
                        ? (user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage("assets/images/default_avatar.png")
                                as ImageProvider)
                        : const AssetImage("assets/images/default_avatar.png"),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushNamed(context, Routes.settings);
                      });
                    },
                  ),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.language),
              title: Text('language'.tr()),
              childrenPadding: const EdgeInsets.only(left: 16),
              children: [
                ListTile(
                  title: Text('turkish'.tr()),
                  onTap: () async {
                    context.setLocale(const Locale("tr", "TR"));
                    await PreferencesService.saveLanguageCode("tr");
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('english'.tr()),
                  onTap: () async {
                    context.setLocale(const Locale("en", "US"));
                    await PreferencesService.saveLanguageCode("en");
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
            ListTile(
              leading: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? Colors.deepOrange : Colors.deepPurple.shade400,
              ),
              title: Text(isDark ? 'light_theme'.tr() : 'dark_theme'.tr()),
              onTap: () {
                themeCubit.toggleTheme();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text('reset_story'.tr()),
              onTap: () async {
                final authCubit = context.read<AuthCubit>();
                final storyCubit = context.read<StoryCubit>();
                await storyCubit.resetStory(authCubit.state);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('story_reset_success'.tr())),
                );
                Navigator.of(context).pop();
              },
            ),
            const Spacer(),
            ListTile(
              leading: Icon(isLoggedIn ? Icons.logout : Icons.login),
              title: Text(isLoggedIn ? 'sign_out'.tr() : 'sign_in'.tr()),
              onTap: () async {
                Navigator.of(context).pop();

                if (isLoggedIn) {
                  await context.read<AuthCubit>().signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.signIn,
                    (route) => false,
                  );
                } else {
                  Navigator.pushNamed(context, Routes.signIn);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
