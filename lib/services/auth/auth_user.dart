import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth show User;
import 'package:flutter/cupertino.dart';

// @immutable tells Flutter that this class or any of its subclass
// needs to be immutable and therefore all the fields in this class cannot be changed
@immutable
class AuthUser {
  /* create our own AuthUser class with 1 attribute isEmailVerified.
  Then we use factory function to copy FirebaseAuth's User's emailVerified property
  to our own AuthUser's isEmailVerified so we not exposing the entire FirebaseAuth's User
  properties to our UI*/
  final String? email;
  final bool isEmailVerified;
  const AuthUser({
    required this.isEmailVerified,
    required this.email,
  });

  factory AuthUser.fromFirebase(FirebaseAuth.User user) => AuthUser(
        email: user.email,
        isEmailVerified: user.emailVerified,
      );
}
