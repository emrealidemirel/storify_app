import 'package:flutter/foundation.dart';
import 'package:flutter_story_app/pages/privacy_page.dart';
import 'package:flutter_story_app/widgets/brand_wordmark.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';
import 'package:flutter_story_app/widgets/sign_in_text_form_field.dart';
import 'package:flutter_story_app/widgets/password_text_form_field.dart';
import 'package:flutter_story_app/widgets/loading_indicator.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();

    return AppScaffold(
      showDrawer: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const BrandWordmark(),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          if (state is AuthAuthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            );
          } else if (state is AuthError) {
            setState(() {
              errorMessage = state.message;
            });
          } else if (state is AuthLoading) {
            errorMessage = null;
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const LoadingIndicator();
          }

          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        'sign_in_title'.tr(),
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      if (errorMessage != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SignInTextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              labelText: 'email_label'.tr(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'email_empty_error'.tr();
                                }
                                if (!RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                ).hasMatch(value.trim())) {
                                  return 'email_invalid_error'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            PasswordTextFormField(
                              controller: _passwordController,
                              labelText: 'password_label'.tr(),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      Routes.passwordReset,
                                    ),
                                child: Text('forgot_password_link'.tr()),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  authCubit.signInWithEmail(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                  );
                                }
                              },
                              child: Text('sign_in'.tr()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'auth_or'.tr(),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerLow,
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(color: scheme.outlineVariant),
                          minimumSize: const Size(48, 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () => authCubit.signInWithGoogle(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google-logo.png',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'google_sign_in_button'.tr(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.iOS) ...[
                        OutlinedButton.icon(
                          onPressed: authCubit.signInWithApple,
                          icon: const Icon(Icons.apple, size: 24),
                          label: Text('apple_sign_in'.tr()),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 56),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const PrivacyLink(),
                      TextButton.icon(
                        onPressed: () => authCubit.signInAnonymously(),
                        icon: const Icon(Icons.explore_outlined, size: 20),
                        label: Text(
                          'auth_guest'.tr(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'sign_up_question'.tr(),
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed:
                                () =>
                                    Navigator.pushNamed(context, Routes.signUp),
                            child: Text('sign_up_link'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
