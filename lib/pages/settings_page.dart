import 'package:flutter_story_app/pages/privacy_page.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:flutter_story_app/widgets/custom_dialog.dart';
import 'package:flutter_story_app/widgets/password_text_form_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';
import 'package:flutter_story_app/widgets/account_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = context.read<AuthCubit>().authRepository.getCurrentUser();
    final isLoggedIn =
        user != null &&
        authState is! AuthUnauthenticated &&
        authState is! AuthLoggedOut;
    final isGuest = user?.isAnonymous ?? true;
    final providerIds =
        user?.providerData.map((provider) => provider.providerId).toSet() ??
        <String>{};
    final isEmailLogin = providerIds.contains('password');
    final isGoogleLogin = providerIds.contains('google.com');

    final name =
        !isLoggedIn || isGuest
            ? 'guest_name'.tr()
            : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : user.email?.split('@').first ?? 'user'.tr());
    return AppScaffold(
      showDrawer: false,
      appBar: AppBar(title: Text('settings'.tr())),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Text(
                'settings_eyebrow'.tr(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'settings_heading'.tr(),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'settings_description'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AccountProfileCard(
                name: name,
                email: isGuest ? null : user?.email,
                photoUrl: isGuest ? null : user?.photoURL,
                guest: isGuest || !isLoggedIn,
                onEditPhoto:
                    isLoggedIn && !isGuest ? _changeProfileImage : null,
              ),
              if (isLoggedIn && !isGuest)
                AccountSection(
                  title: 'profile_section'.tr(),
                  children: [
                    AccountTile(
                      icon: Icons.edit_outlined,
                      title: 'edit_username'.tr(),
                      subtitle: 'username_description'.tr(),
                      onTap: () => _changeDisplayName(user.displayName),
                    ),
                    AccountTile(
                      icon: Icons.portrait_outlined,
                      title: 'edit_profile_photo'.tr(),
                      subtitle: 'photo_description'.tr(),
                      onTap: _changeProfileImage,
                    ),
                  ],
                ),
              if (isEmailLogin)
                AccountSection(
                  title: 'security_section'.tr(),
                  children: [
                    AccountTile(
                      icon: Icons.alternate_email,
                      title: 'change_email'.tr(),
                      subtitle: user?.email,
                      onTap: _changeEmailDialog,
                    ),
                    AccountTile(
                      icon: Icons.lock_outline,
                      title: 'change_password'.tr(),
                      subtitle: 'password_description'.tr(),
                      onTap: _changePasswordDialog,
                    ),
                  ],
                ),
              if (isGoogleLogin && !isEmailLogin && !isGuest)
                AccountSection(
                  title: 'security_section'.tr(),
                  children: [
                    AccountTile(
                      icon: Icons.verified_user_outlined,
                      title: 'google_account'.tr(),
                      subtitle: 'google_account_description'.tr(),
                      trailing: const Icon(Icons.check_circle_outline),
                    ),
                  ],
                ),
              if (!isLoggedIn || isGuest)
                AccountSection(
                  title: 'account_section'.tr(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                      child: Text(
                        'guest_account_description'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    AccountTile(
                      icon: Icons.login_rounded,
                      title: 'sign_in'.tr(),
                      subtitle: 'signin_description'.tr(),
                      onTap: () => Navigator.pushNamed(context, Routes.signIn),
                    ),
                    AccountTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'sign_up_link'.tr(),
                      subtitle: 'signup_description'.tr(),
                      onTap: () => Navigator.pushNamed(context, Routes.signUp),
                    ),
                  ],
                ),
              AccountSection(
                title: 'privacy_title'.tr(),
                children: [
                  AccountTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'privacy_title'.tr(),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPage(),
                          ),
                        ),
                  ),
                  if (isLoggedIn && !isGuest)
                    AccountTile(
                      icon: Icons.smart_toy_outlined,
                      title: 'ai_consent_revoke'.tr(),
                      onTap: () async {
                        await PreferencesService.setAIConsent(user.uid, false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ai_consent_revoked'.tr())),
                        );
                      },
                    ),
                  if (isEmailLogin)
                    AccountTile(
                      icon: Icons.mark_email_read_outlined,
                      title: 'verify_email'.tr(),
                      onTap: () async {
                        try {
                          await context
                              .read<AuthCubit>()
                              .sendEmailVerification();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('verification_sent'.tr())),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('auth_error_general'.tr())),
                          );
                        }
                      },
                    ),
                ],
              ),
              AccountSection(
                title: 'about_section'.tr(),
                children: [
                  AccountTile(
                    icon: Icons.auto_stories_outlined,
                    title: 'about_storify'.tr(),
                    subtitle: 'about_short_description'.tr(),
                    onTap: _showAbout,
                  ),
                ],
              ),
              if (isLoggedIn && !isGuest)
                AccountSection(
                  title: 'account_management_section'.tr(),
                  children: [
                    AccountTile(
                      icon: Icons.delete_outline,
                      title: 'delete_account'.tr(),
                      subtitle: 'delete_account_description'.tr(),
                      danger: true,
                      onTap: () => _confirmAndDeleteAccount(isEmailLogin),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout() => showAboutDialog(
    context: context,
    applicationName: 'Storify',
    applicationIcon: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        'assets/images/storify_icon_with_bg.png',
        width: 56,
        height: 56,
      ),
    ),
    children: [
      Text(
        'about_description'.tr(),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );

  Future<void> _changeDisplayName(String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    final result = await showCustomDialog<String>(
      context: context,
      title: Text('new_username'.tr()),
      content: [
        TextField(
          controller: controller,
          decoration: customInputDecoration('username'.tr(), context),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text('save'.tr()),
        ),
      ],
    );
    controller.dispose();

    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      try {
        await context.read<AuthCubit>().updateProfile(displayName: result);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile_update_success'.tr())));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile_update_error'.tr())));
      }
    }
  }

  Future<void> _changeProfileImage() async {
    final user = context.read<AuthCubit>().authRepository.getCurrentUser();
    if (user == null) return;

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder:
            (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: Text('camera'.tr()),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: Text('gallery'.tr()),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
      );
      if (!mounted || source == null) return;

      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (pickedFile == null) return;

      if (!mounted) return;
      await context.read<AuthCubit>().updateProfile(
        image: File(pickedFile.path),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile_update_success'.tr())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile_update_error'.tr())));
    }
  }

  Future<void> _changePasswordDialog() async {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showCustomDialog<bool>(
      context: context,
      title: Text('change_password'.tr()),
      contentBuilder:
          (ctx) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PasswordTextFormField(
                  controller: currentPwController,
                  labelText: 'current_password'.tr(),
                ),
                SizedBox(height: 2.h),
                PasswordTextFormField(
                  controller: newPwController,
                  labelText: 'new_password'.tr(),
                ),
              ],
            ),
          ),
      actionsBuilder:
          (ctx) => [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
    );

    final currentPassword = currentPwController.text;
    final newPassword = newPwController.text;
    currentPwController.dispose();
    newPwController.dispose();

    if (!mounted) return;
    if (result == true) {
      try {
        final success = await context.read<AuthCubit>().changePassword(
          currentPassword,
          newPassword,
        );
        if (!mounted) return;
        final state = context.read<AuthCubit>().state;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'password_change_success'.tr()
                  : state is AuthError
                  ? state.message
                  : 'auth_error_general'.tr(),
            ),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('password_change_error'.tr())));
      }
    }
  }

  Future<void> _changeEmailDialog() async {
    final emailController = TextEditingController();
    final pwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showCustomDialog<bool>(
      context: context,
      title: Text('change_email'.tr()),
      contentBuilder:
          (ctx) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: customInputDecoration('new_email'.tr(), context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'email_empty_error'.tr();
                    }
                    if (!value.contains('@')) return 'email_invalid_error'.tr();
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                PasswordTextFormField(
                  controller: pwController,
                  labelText: 'current_password'.tr(),
                ),
              ],
            ),
          ),
      actionsBuilder:
          (ctx) => [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
    );

    final newEmail = emailController.text.trim();
    final currentPassword = pwController.text;
    emailController.dispose();
    pwController.dispose();

    if (!mounted) return;
    if (result == true) {
      try {
        final success = await context.read<AuthCubit>().changeEmail(
          newEmail,
          currentPassword,
        );
        if (!mounted) return;
        final state = context.read<AuthCubit>().state;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'email_verification_sent'.tr()
                  : state is AuthError
                  ? state.message
                  : 'auth_error_general'.tr(),
            ),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('email_change_error'.tr())));
      }
    }
  }

  Future<void> _confirmAndDeleteAccount(bool isEmailLogin) async {
    String? password;

    if (isEmailLogin) {
      final pwController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final confirmed = await showCustomDialog<bool>(
        context: context,
        title: Text('delete_account'.tr()),
        contentBuilder:
            (ctx) => Form(
              key: formKey,
              child: PasswordTextFormField(
                controller: pwController,
                labelText: 'current_password'.tr(),
              ),
            ),
        actionsBuilder:
            (ctx) => [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text('delete'.tr()),
              ),
            ],
      );

      final enteredPassword = pwController.text;
      pwController.dispose();

      if (!mounted) return;
      if (confirmed != true) return;
      password = enteredPassword;
    } else {
      final confirmed = await showCustomDialog<bool>(
        context: context,
        title: Text('delete_account'.tr()),
        content: [Text('delete_account_confirm_message'.tr())],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr()),
          ),
        ],
      );

      if (!mounted) return;
      if (confirmed != true) return;
    }

    final deleted = await context.read<AuthCubit>().deleteAccount(password);
    if (!mounted) return;
    if (!deleted) {
      final state = context.read<AuthCubit>().state;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state is AuthError ? state.message : 'auth_error_general'.tr(),
          ),
        ),
      );
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, Routes.signIn, (route) => false);
  }
}
