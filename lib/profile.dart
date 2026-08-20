import 'package:flutter/material.dart';
import 'package:iwantdz/mapscreen.dart';
import 'package:iwantdz/sign.dart';

class LoginContent extends StatefulWidget {
  const LoginContent({super.key});

  @override
  State<LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<LoginContent> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _toggleMode() async {
    // نغيّر الحالة أولًا (نفس مبدأ تحديد الصفحة الجديدة في _switchToPage قبل تشغيل الانيميشن)
    MainNavigation.sineUp = !MainNavigation.sineUp;

    if (MainNavigation.refreshCurrentPage != null) {
      // إغلاق الصفحة بالانيميشن -> إعادة بناء LoginContent بالحالة الجديدة -> فتح بالانيميشن
      // (نفس مبدأ _switchToPage لكن لنفس الصفحة بدل الانتقال لصفحة جديدة)
      await MainNavigation.refreshCurrentPage!();
    } else {
      // احتياطي في حال لم يتم تسجيل refreshCurrentPage من الصفحة المستضيفة بعد
      setState(() {});
      MainNavigation.externalSetstate?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSignUp = MainNavigation.sineUp;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Text(
                isSignUp ? 'Create Account' : 'Welcome Back',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Email field
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              // Confirm email field - only in Sign Up mode
              if (isSignUp) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmEmailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Confirm Email',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Row of 3 buttons: submit (Login/Sign Up) / Google / toggle (Sign Up/Sign In)
              Row(
                children: [
                  // Submit button - label depends on mode
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: handle login/سign-up submit
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isSignUp ? 'Sign Up' : 'Login',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Google sign-in button (icon only, circular)
                  OutlinedButton(
                    onPressed: () {
                      // TODO: handle Google sign-in
                    },
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: Image.network(
                      'https://www.google.com/favicon.ico',
                      height: 20,
                      width: 20,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.g_mobiledata, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Toggle button - flips MainNavigation.sineUp and notifies host page
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _toggleMode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isSignUp ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
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
