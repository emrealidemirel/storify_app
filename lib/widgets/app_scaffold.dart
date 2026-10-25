import 'package:flutter/material.dart';
import 'package:flutter_story_app/widgets/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final bool showDrawer;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.floatingActionButton,
    this.appBar,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:
        appBar ??
        AppBar(title: titleWidget ?? (title != null ? Text(title!) : null)),
    drawer: showDrawer ? const AppDrawer() : null,
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: body,
        ),
      ),
    ),
    floatingActionButton: floatingActionButton,
  );
}
