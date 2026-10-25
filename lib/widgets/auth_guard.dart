import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_story_app/pages/sign_in_page.dart';

/// Only mounts protected content while a Firebase session exists.
/// Anonymous Firebase users are valid sessions too.
class AuthGuard extends StatefulWidget {
  final Widget child;
  final FirebaseAuth? auth;

  const AuthGuard({super.key, required this.child, this.auth});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final FirebaseAuth _auth;
  late final Stream<User?> _authChanges;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _authChanges = _auth.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      initialData: _auth.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError || snapshot.data == null) {
          return const SignInPage();
        }
        return widget.child;
      },
    );
  }
}
