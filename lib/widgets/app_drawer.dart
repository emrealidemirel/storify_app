import 'package:flutter_story_app/widgets/brand_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_story_app/widgets/account_widgets.dart';
import 'package:flutter_story_app/widgets/account_preferences.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = context.read<AuthCubit>().authRepository.getCurrentUser();
    final loggedIn =
        user != null &&
        authState is! AuthUnauthenticated &&
        authState is! AuthLoggedOut;
    final guest = !loggedIn || user.isAnonymous;
    final name =
        guest
            ? 'guest_name'.tr()
            : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : user.email?.split('@').first ?? 'user'.tr());
    final route = ModalRoute.of(context)?.settings.name;
    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(0, 360).toDouble(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const BrandWordmark(),
                  ),
                ),
                IconButton(
                  tooltip: 'close_menu'.tr(),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AccountProfileCard(
              name: name,
              email: guest ? null : user.email,
              photoUrl: guest ? null : user.photoURL,
              guest: guest,
            ),
            AccountSection(
              title: 'explore_section'.tr(),
              children: [
                AccountTile(
                  icon: Icons.home_outlined,
                  title: 'home'.tr(),
                  selected: route == Routes.home,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    if (route != Routes.home) {
                      navigator.pushNamedAndRemoveUntil(
                        Routes.home,
                        (_) => false,
                      );
                    }
                  },
                ),
                AccountTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'settings'.tr(),
                  subtitle: 'settings_short_description'.tr(),
                  selected: route == Routes.settings,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    if (route != Routes.settings) {
                      navigator.pushNamed(Routes.settings);
                    }
                  },
                ),
              ],
            ),
            AccountSection(
              title: 'preferences_section'.tr(),
              children: const [AccountPreferences()],
            ),
            AccountSection(
              title: 'story_section'.tr(),
              children: [
                AccountTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'reset_story'.tr(),
                  subtitle: 'reset_story_description'.tr(),
                  onTap: () => _resetStory(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AccountTile(
              icon: loggedIn ? Icons.logout_rounded : Icons.login_rounded,
              title: (loggedIn ? 'sign_out' : 'sign_in').tr(),
              onTap: () => _signOut(context, loggedIn),
            ),
            const SizedBox(height: 20),
            Text(
              'home_note'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetStory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('reset_story'.tr()),
            content: Text('reset_story_confirmation'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('reset_story'.tr()),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;
    final reset = await context.read<StoryCubit>().resetStory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (reset ? 'story_reset_success' : 'story_error_text').tr(),
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _signOut(BuildContext context, bool loggedIn) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authCubit = context.read<AuthCubit>();
    navigator.pop();
    if (loggedIn) {
      final signedOut = await authCubit.signOut();
      if (!signedOut) {
        final state = authCubit.state;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              state is AuthError
                  ? state.message
                  : 'auth_error_signout_failed'.tr(),
            ),
          ),
        );
        return;
      }
      navigator.pushNamedAndRemoveUntil(Routes.signIn, (_) => false);
    } else {
      navigator.pushNamed(Routes.signIn);
    }
  }
}
