import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/utils/error_dialog.dart';
import 'package:mynotes/views/login_view.dart';

void main() async {
  // enabling widget binding before initialize Firebase in order to bind Firebase
  // with other widgets. This Firebase initialization is used in a Scaffold and Button widget
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginView(),
    ),
  );
}

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // in order to grab information about input email and password when user clicks
  // register, we need to use TextEdittingController to create a proxy for the button
  // to grab the texts which are then used in the onPress func
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    // handle on input change
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
      appBar: AppBar(title: const Text('Register')),
      body: Column(
        children: [
          TextField(
            // hook the controller to its respective text input field
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Enter your email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Enter your password'),
          ),
          TextButton(
            onPressed: () async {
              // anonymous function

              final email = _email.text;
              final password = _password.text;

              try {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                final currentUser = FirebaseAuth.instance.currentUser;
                currentUser?.sendEmailVerification();

                Navigator.of(context).pushNamed(verifyEmailRoute);
              } on FirebaseAuthException catch (err) {
                switch (err.code) {
                  case 'invalid-email':
                    await showErrorDialog(
                      context,
                      err.message.toString(),
                    );
                    break;
                  case 'email-already-in-use':
                    await showErrorDialog(
                      context,
                      err.message.toString(),
                    );
                    break;
                  case 'weak-password':
                    await showErrorDialog(
                      context,
                      err.message.toString(),
                    );
                    break;
                  default:
                    await showErrorDialog(
                      context,
                      err.message.toString(),
                    );
                    break;
                }
              } catch (err) {
                await showErrorDialog(
                  context,
                  err.toString(),
                );
              }
            },
            child: const Text('Register'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text('Already registered? Log in here!'),
          )
        ],
      ),
    );
  }
}
