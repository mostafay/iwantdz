import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iwantdz/curved/src/storage_helper.dart';
import 'package:iwantdz/mapscreen.dart';
import 'package:iwantdz/config.dart';

class LoginContent extends StatefulWidget {
  const LoginContent({super.key});

  @override
  State<LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<LoginContent> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
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

  Future<void> _handleSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print('=== بدء عملية تسجيل مستخدم جديد ===');
    print('اسم المستخدم: $username');
    print('البريد الإلكتروني: $email');
    print('كلمة المرور: ${password.length > 0 ? "******" : "فارغ"}');

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      print('❌ خطأ: البيانات غير مكتملة');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      }
      return;
    }

    print('📡 إرسال طلب تسجيل مستخدم جديد إلى الخادم...');

    try {
      final response = await http.post(
        Uri.parse(AppConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );

      print('📥 استجابة الخادم:');
      print('حالة الاستجابة: ${response.statusCode}');
      print('نص الاستجابة: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('📊 البيانات المستلمة:');
        print(data.toString());

        if (data['success'] == true) {
          print('✅ تسجيل المستخدم ناجح');

          // حفظ بيانات المستخدم في MainNavigation.userdata
          if (data['user'] != null) {
            MainNavigation.userdata = data['user'];
            print('💾 تم حفظ بيانات المستخدم في MainNavigation.userdata');
          }

          // استخراج Oid مباشرة من الـ response
          String oid = data['oid'] ?? '';
          print('🔑 Oid المستخرج: $oid');

          // حفظ Oid في MainNavigation.sineKey
          MainNavigation.sineKey = oid;
          print('💾 تم حفظ Oid في MainNavigation.sineKey');

          // حفظ Oid في ملف محلي
          await StorageHelper.saveOid(oid);

          // استخراج وحفظ BID من بيانات المستخدم
          if (data['user'] != null && data['user']['BID'] != null) {
            final bid = data['user']['BID'];
            MainNavigation.sineBID = bid;
            await StorageHelper.saveBID(bid);
            print('💾 تم حفظ BID في MainNavigation.sineBID: $bid');
          }

          // تعيين حالة تسجيل الدخول
          MainNavigation.IsrealySined = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful')));
          }
          // التبديل إلى وضع تسجيل الدخول
          await _toggleMode();
        } else {
          print('❌ فشل التسجيل: ${data['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Registration failed')));
          }
        }
      } else {
        print('❌ خطأ في الخادم: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${response.statusCode}')));
        }
      }
    } catch (e) {
      print('❌ استثناء: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    print('=== انتهت عملية تسجيل المستخدم ===');
  }

  Future<void> _handleLogin() async {
    String email = 'newuser2@gmail.com';
    String password = '12345678';

    if (_emailController.text != '') email = _emailController.text;
    if (_passwordController.text != '') password = _passwordController.text;

    print('=== بدء عملية تسجيل الدخول ===');
    print('البريد الإلكتروني: $email');
    print('كلمة المرور: ${password.length > 0 ? "******" : "فارغ"}');

    if (email.isEmpty || password.isEmpty) {
      print('❌ خطأ: البريد الإلكتروني أو كلمة المرور فارغة');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }

    print('📡 إرسال طلب تسجيل الدخول إلى الخادم...');

    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📥 استجابة الخادم:');
      print('حالة الاستجابة: ${response.statusCode}');
      print('نص الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 البيانات المستلمة:');
        print(data.toString());

        if (data['success'] == true && data['user'] != null) {
          print('✅ تسجيل الدخول ناجح');

          // حفظ بيانات المستخدم في MainNavigation.userdata
          MainNavigation.userdata = data['user'];
          print('💾 تم حفظ بيانات المستخدم في MainNavigation.userdata');

          // استخراج Oid مباشرة من الـ response
          String oid = data['oid'] ?? '';
          print('🔑 Oid المستخرج: $oid');

          // حفظ Oid في MainNavigation.sineKey
          MainNavigation.sineKey = oid;
          print('💾 تم حفظ Oid في MainNavigation.sineKey');

          // حفظ Oid في ملف محلي
          await StorageHelper.saveOid(oid);

          // استخراج وحفظ BID من بيانات المستخدم
          if (data['user'] != null && data['user']['BID'] != null) {
            final bid = data['user']['BID'];
            MainNavigation.sineBID = bid;
            await StorageHelper.saveBID(bid);
            print('💾 تم حفظ BID في MainNavigation.sineBID: $bid');
          }

          // تعيين حالة تسجيل الدخول
          MainNavigation.IsrealySined = true;

          // تحديث الـ UI
          print('🔄 تحديث الواجهة...');
          if (MainNavigation.refreshCurrentPage != null) {
            await MainNavigation.refreshCurrentPage!();
          } else {
            setState(() {});
            MainNavigation.externalSetstate?.call();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful')));
          }
          print('✨ تم تحديث الواجهة بنجاح');
        } else {
          print('❌ فشل تسجيل الدخول: ${data['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Login failed')));
          }
        }
      } else {
        print('❌ خطأ في الخادم: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: ${response.statusCode}')));
        }
      }
    } catch (e) {
      print('❌ استثناء: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    print('=== انتهت عملية تسجيل الدخول ===');
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

              // Username field - only in Sign Up mode
              if (isSignUp) ...[
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                      onPressed: isSignUp ? _handleSignUp : _handleLogin,
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
