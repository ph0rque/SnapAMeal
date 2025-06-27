import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isLoading = false;

  void login(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple simultaneous login attempts

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();

    // try login
    try {
      await authService.signInWithEmailPassword(
        _emailController.text,
        _pwController.text,
      );
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _demoLogin(BuildContext context, String persona) async {
    if (_isLoading) return; // Prevent multiple simultaneous login attempts

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();

    // try demo login
    try {
      await authService.signInWithDemoAccount(persona);
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Demo Login Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // logo
                  const Icon(EvaIcons.messageSquare, size: 60),

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
                        color: SnapUIColors.primaryYellow.withValues(
                          alpha: 0.3,
                        ),
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

                  // demo login section
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: SnapUIColors.secondaryDark.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: SnapUIColors.secondaryDark.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Quick Demo Login",
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SnapUIColors.secondaryDark,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SnapButton(
                                onTap: _isLoading
                                    ? null
                                    : () => _demoLogin(context, 'alice'),
                                text: "Alice",
                                type: SnapButtonType.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SnapButton(
                                onTap: _isLoading
                                    ? null
                                    : () => _demoLogin(context, 'bob'),
                                text: "Bob",
                                type: SnapButtonType.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SnapButton(
                                onTap: _isLoading
                                    ? null
                                                      : () => _demoLogin(context, 'charlie'),
              text: "Chuck",
                                type: SnapButtonType.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "or",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: SnapUIColors.secondaryDark.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
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
                    onTap: _isLoading ? null : () => login(context),
                    text: _isLoading ? "Signing in..." : "Login",
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
                        onTap: widget.onTap,
                        child: Text(
                          "Register now",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
