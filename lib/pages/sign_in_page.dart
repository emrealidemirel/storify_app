import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:flutter_story_app/contants/routes.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';
import 'package:flutter_story_app/widgets/sign_in_text_form_field.dart';
import 'package:flutter_story_app/widgets/password_text_form_field.dart'; 
import 'package:flutter_story_app/widgets/loading_indicator.dart';
import 'package:flutter_story_app/widgets/sign_in_button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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
      appBar: AppBar(
        title: Text(
          "app_title".tr(),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacementNamed(context, Routes.home);
          } else if (state is AuthError) {
            setState(() {
              errorMessage = state.message;
            });
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const LoadingIndicator();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "sign_in_title".tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (errorMessage != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 4.h),
                Form(
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
                      SizedBox(height: 1.h),

                      
                      PasswordTextFormField(
                        controller: _passwordController,
                        labelText: "password_label".tr(),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.passwordReset);
                          },
                          child: Text(
                            "forgot_password_link".tr(),
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SignInButton(
                        buttonText: "sign_in".tr(),
                        buttonColor: Theme.of(context).primaryColor,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            authCubit.signInWithEmail(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'sign_up_question'.tr(),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
                SizedBox(height: 8.h),
                SignInButton(
                  buttonText: "google_sign_in_button".tr(),
                  buttonColor: Colors.white,
                  textColor: Colors.black.withAlpha(140),
                  buttonIcon: Image.asset("assets/images/google-logo.png"),
                  onPressed: () {
                    authCubit.signInWithGoogle();
                  },
                ),
                SignInButton(
                  buttonText: "anonymous_sign_in_button".tr(),
                  buttonIcon: Icon(Icons.supervised_user_circle, size: 30),
                  buttonColor: Colors.grey.shade700,
                  onPressed: () {
                    authCubit.signInAnonymously();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
