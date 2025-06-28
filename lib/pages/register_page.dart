import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();

  final void Function()? onTap;

  RegisterPage({super.key, required this.onTap});

  void register(BuildContext context) async {
    // get auth service
    final authService = AuthService();

    // show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // password match -> create user
    if (_pwController.text == _confirmPwController.text) {
      try {
        await authService.signUpWithEmailPassword(
          _emailController.text,
          _pwController.text,
          _usernameController.text,
        );

        // pop loading circle
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        // pop loading circle
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(title: Text(e.toString())),
          );
        }
      }
    }
    // passwords don't match -> tell user to fix
    else {
      // pop loading circle
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              const AlertDialog(title: Text("Passwords don't match!")),
        );
      }
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
              const Icon(EvaIcons.messageSquare, size: 60),

              const SizedBox(height: 50),

              // welcome back message
              Text(
                "Let's create an account for you",
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 25),

              // username textfield
              SnapTextField(
                controller: _usernameController,
                hintText: "Username",
                obscureText: false,
              ),

              const SizedBox(height: 10),

              // email textfield
              SnapTextField(
                controller: _emailController,
                hintText: "Email",
                obscureText: false,
              ),

              const SizedBox(height: 10),

              // password textfield
              SnapTextField(
                controller: _pwController,
                hintText: "Password",
                obscureText: true,
              ),

              const SizedBox(height: 10),

              // confirm password textfield
              SnapTextField(
                controller: _confirmPwController,
                hintText: "Confirm Password",
                obscureText: true,
              ),

              const SizedBox(height: 25),

              // register button
              SnapButton(onTap: () => register(context), text: "Register"),

              const SizedBox(height: 25),

              // register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already a member? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      "Login now",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
