import 'package:flutter/material.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/components/my_button.dart';
import 'package:snapameal/components/my_textfield.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();

  final void Function()? onTap;

  RegisterPage({super.key, required this.onTap});

  void register(BuildContext context) async {
    // get auth service
    final _auth = AuthService();

    // show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // password match -> create user
    if (_pwController.text == _confirmPwController.text) {
      try {
        await _auth.signUpWithEmailPassword(
          _emailController.text,
          _pwController.text,
          _usernameController.text,
        );

        // pop loading circle
        if (context.mounted) Navigator.pop(context);

      } catch (e) {
        // pop loading circle
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
        );
      }
    }

    // passwords don't match -> tell user to fix
    else {
      // pop loading circle
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Passwords don't match!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // logo
              Icon(
                Icons.message,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 50),

              // welcome back message
              Text(
                "Let's create an account for you",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // username textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: MyTextField(
                  hintText: "Username",
                  obscureText: false,
                  controller: _usernameController,
                ),
              ),

              const SizedBox(height: 10),

              // email textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: MyTextField(
                  hintText: "Email",
                  obscureText: false,
                  controller: _emailController,
                ),
              ),

              const SizedBox(height: 10),

              // pw textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: _pwController,
                ),
              ),

              const SizedBox(height: 10),

              // confirm pw textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: MyTextField(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: _confirmPwController,
                ),
              ),

              const SizedBox(height: 25),

              // login button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: MyButton(
                  text: "Register",
                  onTap: () => register(context),
                ),
              ),

              const SizedBox(height: 25),

              // register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  TextButton(
                    onPressed: onTap,
                    child: Text(
                      "Login now",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 