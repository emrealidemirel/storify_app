import 'package:flutter/widgets.dart';
import 'package:flutter_story_app/pages/home_page.dart';
import 'package:flutter_story_app/pages/reset_password_page.dart';
import 'package:flutter_story_app/pages/sign_in_page.dart';
import 'package:flutter_story_app/pages/sign_up_page.dart';
import 'package:flutter_story_app/pages/settings_page.dart';

class Routes {
  static const String language = "/language";
  static const String home = "/home";
  static const String signIn = "/signIn";
  static const String signUp = "/signUp";
  static const String passwordReset = "/passwordReset";
  static const String settings = "/settings";

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => HomePage(),
      signIn: (context) => const SignInPage(),
      signUp: (context) => const SignUpPage(),
      passwordReset: (context) => const ResetPasswordPage(),
      settings: (context) => const SettingsPage(),
    };
  }
}
