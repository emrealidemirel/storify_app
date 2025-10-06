import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_story_app/contants/routes.dart';
import 'package:flutter_story_app/widgets/sign_in_text_form_field.dart';
import 'package:flutter_story_app/widgets/sign_in_button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold( 
      appBar: AppBar(title: Text('app_title'.tr())),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetEmailSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('reset_password_email_sent'.tr())),
            );
            Navigator.pop(context);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
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
                        if (val == null || !val.contains('@')) {
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
        ),
      ),
    );
  }
}