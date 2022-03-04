import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';

import '../utils/error_dialog.dart';

class LoginView extends StatefulWidget {
  // since homepage has the 2 input fields whose value can be changed, this makes
  // the Homepage a stateful widget
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email',
            ),
          ),
          TextField(
            controller: _password,
            autocorrect: false,
            enableSuggestions: false,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter your password',
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser?.emailVerified ?? false) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    notesRoute,
                    (route) => false,
                  );
                } else {
                  Navigator.of(context).pushNamed(verifyEmailRoute);
                }
              } on FirebaseAuthException catch (err) {
                // use print(err.runtimeType) to find out what type of Exception Error it is
                // and then we catch that exact error instead of a generic catch all error
                // Then we can display exactly error msg that user doesn't exist
                // print(err.code);
                if (err.code == 'user-not-found') {
                  await showErrorDialog(
                    context,
                    'User not found.',
                  );
                } else if (err.code == 'wrong-password') {
                  await showErrorDialog(
                    context,
                    'Wrong password.',
                  );
                } else {
                  await showErrorDialog(
                    context,
                    'Woops! ${err.message.toString()}',
                  );
                }
              } catch (err) {
                await showErrorDialog(
                  context,
                  err.toString(),
                );
              }
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute,
                (route) => false,
              );
            },
            child: const Text('Not register yet? Register here!'),
          ),
        ],
      ),
    );
  }
}
