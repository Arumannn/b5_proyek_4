import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_overlay.dart';
import 'auth_controller.dart';
import 'login_view.dart';

/// Layar registrasi user baru dengan pendekatan offline-first.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _divisiController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ValueNotifier<String> _selectedRole = ValueNotifier(AppConstants.roleMember);
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final ValueNotifier<bool> _obscureConfirmPassword = ValueNotifier(true);

  final AuthController _authController = AuthController.instance;

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _divisiController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _selectedRole.dispose();
    _obscurePassword.dispose();
    _obscureConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await _authController.register(
      nama: _namaController.text,
      nim: _nimController.text,
      divisi: _divisiController.text,
      role: _selectedRole.value,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackbar.showSuccess(
        context,
        'Registrasi berhasil. Silakan login.',
      );
      _authController.clearSession();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginView()),
      );
      return;
    }

    CustomSnackbar.showError(
      context,
      _authController.errorMessage.value ?? 'Registrasi gagal.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _authController.isLoading,
      builder: (context, isLoading, _) {
        return LoadingOverlay(
          isLoading: isLoading,
          message: 'Menyimpan akun...',
          child: Scaffold(
            appBar: AppBar(title: const Text('Daftar Akun')),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _namaController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nama wajib diisi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
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
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _divisiController,
                                decoration: const InputDecoration(
                                  labelText: 'Divisi',
                                  prefixIcon: Icon(Icons.groups_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Divisi wajib diisi.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<String>(
                                valueListenable: _selectedRole,
                                builder: (_, role, __) {
                                  return DropdownButtonFormField<String>(
                                    value: role,
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: AppConstants.roleMember,
                                        child: Text(AppConstants.roleMember),
                                      ),
                                      DropdownMenuItem(
                                        value: AppConstants.roleAdmin,
                                        child: Text(AppConstants.roleAdmin),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        _selectedRole.value = value;
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<bool>(
                                valueListenable: _obscurePassword,
                                builder: (_, obscure, __) {
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
                                      if (value.length < 6) {
                                        return 'Password minimal 6 karakter.';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<bool>(
                                valueListenable: _obscureConfirmPassword,
                                builder: (_, obscure, __) {
                                  return TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: obscure,
                                    decoration: InputDecoration(
                                      labelText: 'Konfirmasi Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          _obscureConfirmPassword.value = !obscure;
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
                                        return 'Konfirmasi password wajib diisi.';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Password tidak sama.';
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
                                    padding: const EdgeInsets.only(bottom: 10),
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
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _onRegisterPressed,
                                  child: const Text('Daftar'),
                                ),
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