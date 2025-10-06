import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/services/firebase_auth_service.dart';
import 'package:flutter_story_app/services/firebase_storage_service.dart';
import 'package:flutter_story_app/contants/routes.dart';
import 'package:flutter_story_app/widgets/custom_dialog.dart';
import 'package:flutter_story_app/widgets/password_text_form_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';

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
    final isLoggedIn = authState is AuthAuthenticated;
    final user = isLoggedIn ? authState.user : null;
    final isGuest = user?.isAnonymous ?? true;
    final providerId =
        (user != null && user.providerData.isNotEmpty)
            ? user.providerData.first.providerId
            : null;
    final isEmailLogin = providerId == 'password';
    final isGoogleLogin = providerId == 'google.com';

    return AppScaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          if (isLoggedIn && !isGuest) ...[
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              title: Text('edit_username'.tr()),
              onTap: () => _changeDisplayName(user?.displayName),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
              title: Text('edit_profile_photo'.tr()),
              onTap: _changeProfileImage,
            ),
          ],
          if (isEmailLogin) ...[
            ListTile(
              leading: Icon(Icons.lock, color: Theme.of(context).primaryColor),
              title: Text('change_password'.tr()),
              onTap: _changePasswordDialog,
            ),
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).primaryColor),
              title: Text('change_email'.tr()),
              onTap: _changeEmailDialog,
            ),
          ],
          if ((isEmailLogin || isGoogleLogin) && !isGuest)
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).primaryColor),
              title: Text('delete_account'.tr()),
              onTap: () => _confirmAndDeleteAccount(isEmailLogin),
            ),
          if (!isLoggedIn || isGuest) ...[
            ListTile(
              title: Text('sign_in'.tr()),
              onTap: () => Navigator.pushNamed(context, Routes.signIn),
            ),
            ListTile(
              title: Text('sign_up'.tr()),
              onTap: () => Navigator.pushNamed(context, Routes.signUp),
            ),
          ],
        ],
      ),
    );
  }

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
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text('save'.tr()),
        ),
      ],
    );

    if (!mounted) return; 
    if (result != null && result.isNotEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(result);
          await user.reload();
          if (!mounted) return;
          await context.read<AuthCubit>().checkAuthStatus();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_update_success'.tr())));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_update_error'.tr())));
      }
    }
  }

  Future<void> _changeProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final downloadUrl = await FirebaseStorageService.uploadUserProfileImage(file, user.uid);
    if (!mounted) return;

    if (downloadUrl != null) {
      final repo = context.read<AuthCubit>().authRepository;
      if (repo is FirebaseAuthService) {
        await repo.updateProfilePhoto(downloadUrl);
        if (!mounted) return;
        await context.read<AuthCubit>().checkAuthStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_update_success'.tr())));
      }
    }
  }

  Future<void> _changePasswordDialog() async {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showCustomDialog<bool>(
      context: context,
      title: Text('change_password'.tr()),
      contentBuilder: (ctx) => Form(
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
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
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

    if (!mounted) return;
    if (result == true) {
      try {
        await context.read<AuthCubit>().changePassword(
          currentPwController.text.trim(),
          newPwController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('password_change_success'.tr())));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('password_change_error'.tr())));
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
      contentBuilder: (ctx) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: emailController,
              decoration: customInputDecoration('new_email'.tr(), context),
              validator: (value) {
                if (value == null || value.isEmpty) return 'email_empty_error'.tr();
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
      actionsBuilder: (ctx) => [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
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

    if (!mounted) return;
    if (result == true) {
      try {
        await context.read<AuthCubit>().changeEmail(
          emailController.text.trim(),
          pwController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('email_verification_sent'.tr())));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('email_change_error'.tr())));
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
        contentBuilder: (ctx) => Form(
          key: formKey,
          child: PasswordTextFormField(
            controller: pwController,
            labelText: 'current_password'.tr(),
          ),
        ),
        actionsBuilder: (ctx) => [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
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

      if (!mounted) return;
      if (confirmed != true) return;
      password = pwController.text.trim();
    } else {
      final confirmed = await showCustomDialog<bool>(
        context: context,
        title: Text('delete_account'.tr()),
        content: [Text('delete_account_confirm_message'.tr())],
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('delete'.tr())),
        ],
      );

      if (!mounted) return;
      if (confirmed != true) return;
    }

    await context.read<AuthCubit>().deleteAccount(password);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.signIn, (route) => false);
  }
}
