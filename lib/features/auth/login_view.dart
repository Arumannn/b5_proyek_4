import 'package:flutter/material.dart';

import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_overlay.dart';
import 'auth_controller.dart';
import 'register_view.dart';

/// Layar Login dengan state reaktif dari AuthController.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final AuthController _authController = AuthController.instance;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await _authController.login(
      context: context,
      nim: _nimController.text,
      password: _passwordController.text,
    );

    if (!success && mounted) {
      CustomSnackbar.showError(
        context,
        _authController.errorMessage.value ?? 'Login gagal.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _authController.isLoading,
      builder: (context, isLoading, _) {
        return LoadingOverlay(
          isLoading: isLoading,
          message: 'Memproses login...',
          child: Scaffold(
            backgroundColor: const Color(0xFF1B3A6B),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 52,
                                color: Color(0xFF1B3A6B),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Masuk ke PRASASTI',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _nimController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'NIM',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'NIM wajib diisi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              ValueListenableBuilder<bool>(
                                valueListenable: _obscurePassword,
                                builder: (context, obscure, __) {
                                  return TextFormField(
                                    controller: _passwordController,
                                    obscureText: obscure,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.key_outlined),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          _obscurePassword.value = !obscure;
                                        },
                                        icon: Icon(
                                          obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password wajib diisi.';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              ValueListenableBuilder<String?>(
                                valueListenable: _authController.errorMessage,
                                builder: (_, message, __) {
                                  if (message == null || message.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: isLoading ? null : _onLoginPressed,
                                child: const Text('Login'),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => const RegisterView(),
                                          ),
                                        );
                                      },
                                child: const Text('Belum punya akun? Daftar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}