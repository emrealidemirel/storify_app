import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/pages/sign_in_page.dart';
import 'package:flutter_story_app/repositories/auth_repository.dart';
import 'package:flutter_story_app/widgets/auth_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class _Auth extends Fake implements FirebaseAuth {
  User? user;
  final changes = StreamController<User?>.broadcast();

  _Auth(this.user);

  @override
  User? get currentUser => user;

  @override
  Stream<User?> authStateChanges() => changes.stream;

  void update(User? value) {
    user = value;
    changes.add(value);
  }
}

class _User extends Fake implements User {
  @override
  final bool isAnonymous;
  _User({required this.isAnonymous});
}

class _Repository extends Fake implements AuthRepository {
  final _Auth auth;
  _Repository(this.auth);

  @override
  User? getCurrentUser() => auth.currentUser;
}

Widget _app(_Auth auth) => BlocProvider(
  create: (_) => AuthCubit(authRepository: _Repository(auth)),
  child: ResponsiveSizer(
    builder:
        (context, orientation, screenType) => MaterialApp(
          home: AuthGuard(auth: auth, child: const Text('Protected home')),
        ),
  ),
);

void main() {
  testWidgets('no session shows sign-in with no home navigation bypass', (
    tester,
  ) async {
    final auth = _Auth(null);
    addTearDown(auth.changes.close);
    await tester.pumpWidget(_app(auth));
    await tester.pump();

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.text('Protected home'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byType(Drawer), findsNothing);
  });

  for (final guest in [true, false]) {
    testWidgets(
      'a ${guest ? "guest" : "registered"} session allows home and sign-out hides it',
      (tester) async {
        final auth = _Auth(_User(isAnonymous: guest));
        addTearDown(auth.changes.close);
        await tester.pumpWidget(_app(auth));
        expect(find.text('Protected home'), findsOneWidget);
        expect(find.byType(SignInPage), findsNothing);

        auth.update(null);
        await tester.pump();
        expect(find.text('Protected home'), findsNothing);
        expect(find.byType(SignInPage), findsOneWidget);
      },
    );
  }

  testWidgets('successful guest authentication unlocks protected content', (
    tester,
  ) async {
    final auth = _Auth(null);
    addTearDown(auth.changes.close);
    await tester.pumpWidget(_app(auth));
    auth.update(_User(isAnonymous: true));
    await tester.pump();

    expect(find.text('Protected home'), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
  });
}
