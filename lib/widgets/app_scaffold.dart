import 'package:flutter/material.dart';
import 'package:flutter_story_app/widgets/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        appBar: appBar ?? AppBar(title: title != null ? Text(title!) : null),
        drawer: const AppDrawer(),
        body: body,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
