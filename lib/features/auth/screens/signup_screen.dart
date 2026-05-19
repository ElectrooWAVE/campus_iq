import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _branch = AppConstants.branches.first;
  int? _year;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool get _isAdmin => _tabCtrl.index == 0;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAdmin && _year == null) {
      AppSnackBar.error(context, 'Please select your year of study');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.signup(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role: _isAdmin ? 'admin' : 'student',
      branch: _branch,
      year: _isAdmin ? null : _year,
    );

    if (!mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error);
    } else {
      context.go(auth.isAdmin ? '/admin/home' : '/student/home');
    }
  }

  Widget _buildYearPills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Year', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            final yr = i + 1;
            final selected = _year == yr;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _year = yr),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${yr}${_yearSuffix(yr)}',
                        style: AppTextStyles.label.copyWith(
                          color: selected ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _yearSuffix(int yr) {
    if (yr == 1) return 'st';
    if (yr == 2) return 'nd';
    if (yr == 3) return 'rd';
    return 'th';
  }

  Widget _buildBranchDropdown(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _branch,
          decoration: const InputDecoration(),
          isExpanded: true,
          items: AppConstants.branches
              .map((b) => DropdownMenuItem(value: b, child: Text(b, style: AppTextStyles.body)))
              .toList(),
          onChanged: (v) => setState(() => _branch = v!),
        ),
      ],
    );
  }

  Widget _buildCommonFields(String nameHint) {
    return Column(
      children: [
        AppTextField(
          label: 'Your Full Name',
          hint: nameHint,
          controller: _nameCtrl,
          prefix: const Icon(LucideIcons.user, size: 18),
          validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'College Email',
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
          hint: 'Min. 8 characters',
          controller: _passCtrl,
          obscure: _obscurePass,
          prefix: const Icon(LucideIcons.lock, size: 18),
          suffix: IconButton(
            icon: Icon(_obscurePass ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Confirm Password',
          hint: 'Repeat your password',
          controller: _confirmPassCtrl,
          obscure: _obscureConfirm,
          prefix: const Icon(LucideIcons.lock, size: 18),
          suffix: IconButton(
            icon: Icon(_obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          validator: (v) {
            if (v != _passCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Icon(LucideIcons.arrowLeft),
                ),
                const SizedBox(height: 24),
                Text('Create Account', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  'Join CampusIQ today',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                // Role toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    onTap: (_) => setState(() {}),
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: AppTextStyles.bodyMedium,
                    tabs: const [
                      Tab(text: 'Admin'),
                      Tab(text: 'Student'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Admin form
                if (_isAdmin) ...[
                  _buildCommonFields('e.g. Dr. Ramesh Kumar'),
                  const SizedBox(height: 16),
                  _buildBranchDropdown('Department You Manage'),
                ] else ...[
                  // Student form
                  _buildCommonFields('e.g. Priya Sharma'),
                  const SizedBox(height: 16),
                  _buildBranchDropdown('Your Branch'),
                  const SizedBox(height: 16),
                  _buildYearPills(),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Create Account',
                    onPressed: _signup,
                    isLoading: auth.isLoading,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        children: [
                          TextSpan(
                            text: 'Login',
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
    );
  }
}
