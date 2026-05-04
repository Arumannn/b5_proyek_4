// ignore_for_file: unused_import

import 'package:flutter/material.dart';

import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_overlay.dart';
import 'auth_controller.dart';

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
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEAF2FF), Color(0xFFF9FAFB)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x332563EB),
                                      blurRadius: 24,
                                      offset: Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'PRASASTI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Masuk untuk mengelola absensi, event, dan anggota.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              elevation: 10,
                              shadowColor: const Color(0x1A000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Login',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gunakan akun yang sudah terdaftar.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.black54,
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
                                        builder: (context, obscure, child) {
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
                                        builder: (context, message, child) {
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
                                      Text(
                                        'Pembuatan akun hanya oleh Executive.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
