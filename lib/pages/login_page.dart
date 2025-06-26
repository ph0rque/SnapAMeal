import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  final void Function()? onTap;

  LoginPage({super.key, required this.onTap});

  void login(BuildContext context) async {
    // auth service
    final authService = AuthService();

    // show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // try login
    try {
      await authService.signInWithEmailPassword(
        _emailController.text,
        _pwController.text,
      );

      // pop loading circle
      if (context.mounted) Navigator.pop(context);
    }

    // catch any errors
    catch (e) {
      // pop loading circle
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
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
              const Icon(
                EvaIcons.messageSquare,
                size: 60,
              ),

              const SizedBox(height: 50),

              // welcome back message
              Text(
                "Welcome back, you've been missed!",
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 10),

              // user switching info
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: SnapUIColors.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SnapUIColors.primaryYellow.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  "💡 Tip: You can easily switch between different user accounts by logging out and logging back in with different credentials.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SnapUIColors.secondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 25),

              // email textfield
              SnapTextField(
                hintText: "Email",
                obscureText: false,
                controller: _emailController,
              ),

              const SizedBox(height: 10),

              // pw textfield
              SnapTextField(
                hintText: "Password",
                obscureText: true,
                controller: _pwController,
              ),

              const SizedBox(height: 25),

              // sign in button
              SnapButton(
                onTap: () => login(context),
                text: "Login",
              ),

              const SizedBox(height: 25),

              // register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Not a member? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      "Register now",
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