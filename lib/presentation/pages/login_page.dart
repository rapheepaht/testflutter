import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:testflutter/presentation/routes/app_router.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: scheme.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'จดโน้ต',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primaryContainer,
                      scheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 44),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 64,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'อีเมล',
                        hintText: 'example@gmail.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'กรุณากรอกอีเมล';
                        }
                        if (!value!.contains('@')) {
                          return 'อีเมลไม่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        hintText: 'ป้อนรหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'กรุณากรอกรหัสผ่าน';
                        }
                        if ((value?.length ?? 0) < 6) {
                          return 'รหัสผ่านต้องมี 6 ตัวขึ้นไป';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ลิงค์รีเซ็ตรหัสผ่านส่งไปแล้ว'),
                            ),
                          );
                        },
                        child: Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(color: scheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  scheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: scheme.outlineVariant),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'หรือ',
                            style: TextStyle(color: scheme.outlineVariant),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: scheme.outlineVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ยังไม่มีบัญชี? '),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ไปยังหน้าสมัครสมาชิก'),
                              ),
                            );
                          },
                          child: Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              color: scheme.primary,
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
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Navigate to home page
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'สวัสดีคุณ ${_emailController.text.split('@')[0]}!',
          ),
        ),
      );
      context.router.pushAndPopUntil(
        HomeRoute(email: _emailController.text),
        predicate: (_) => false,
      );
    }
  }
}
