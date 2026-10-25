import 'package:flutter_story_app/widgets/brand_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:flutter_story_app/widgets/sign_in_text_form_field.dart';
import 'package:flutter_story_app/widgets/sign_in_button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';
import 'package:flutter_story_app/widgets/loading_indicator.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().resetPassword(emailController.text.trim());
    }
  }

  void _cancel() {
    context.read<AuthCubit>().cancelPasswordReset();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<AuthCubit>().cancelPasswordReset();
      },
      child: AppScaffold(
        showDrawer: false,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'cancel'.tr(),
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancel,
          ),
          title: const BrandWordmark(),
        ),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthPasswordResetEmailSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('reset_password_email_sent'.tr())),
              );
              Navigator.pop(context);
            } else if (state is AuthPasswordResetError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) return const LoadingIndicator();
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SignInTextFormField(
                          controller: emailController,
                          labelText: 'email_label'.tr(),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'email_empty_error'.tr();
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                              return 'email_invalid_error'.tr();
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 4.h),
                        SignInButton(
                          buttonText: 'reset_password_button'.tr(),
                          buttonColor: Theme.of(context).primaryColor,
                          onPressed: _submit,
                        ),
                        SizedBox(height: 2.h),
                        TextButton.icon(
                          onPressed: _cancel,
                          icon: const Icon(Icons.arrow_back),
                          label: Text('cancel'.tr()),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'sign_up_question'.tr(),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, Routes.signUp);
                              },
                              child: Text(
                                'sign_up_link'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.2,
                                  decorationStyle: TextDecorationStyle.solid,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
