import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error);
    } else {
      context.go(auth.isAdmin ? '/admin/home' : '/student/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        LucideIcons.graduationCap,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('CampusIQ', style: AppTextStyles.h1.copyWith(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    )),
                  ),
                  Center(
                    child: Text(
                      'Your college. Simplified.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text('Welcome back', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text('Sign in to continue', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Email Address',
                    hint: 'you@college.edu',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(LucideIcons.mail, size: 18),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordCtrl,
                    obscure: _obscure,
                    prefix: const Icon(LucideIcons.lock, size: 18),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Login',
                      onPressed: _login,
                      isLoading: auth.isLoading,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
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
    );
  }
}
