import 'package:flutter_story_app/pages/privacy_page.dart';
import 'package:flutter_story_app/widgets/brand_wordmark.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:flutter_story_app/widgets/sign_in_text_form_field.dart';
import 'package:flutter_story_app/widgets/sign_in_button.dart';
import 'package:flutter_story_app/widgets/password_text_form_field.dart';
import 'package:flutter_story_app/widgets/loading_indicator.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showDrawer: false,
      appBar: AppBar(title: const BrandWordmark()),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) return const LoadingIndicator();
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SignInTextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    labelText: "email_label".tr(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'email_empty_error'.tr();
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'email_invalid_error'.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),

                  PasswordTextFormField(
                    controller: _passwordController,
                    labelText: "password_label".tr(),
                  ),

                  const PrivacyLink(),
                  SizedBox(height: 4.h),
                  SignInButton(
                    buttonText: 'sign_up'.tr(),
                    buttonColor: Theme.of(context).primaryColor,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 2.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'sign_in_question'.tr(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.signIn);
                        },
                        child: Text(
                          'sign_in'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
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
          );
        },
      ),
    );
  }
}
