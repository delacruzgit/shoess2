import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final box = Hive.box("shoestore_db");
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _fullName = TextEditingController();

  String errorMsg = "";
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    isDark = box.get("isDark", defaultValue: true);
  }

  Future<void> _signup() async {
    // Validation
    if (_username.text.trim().isEmpty) {
      setState(() {
        errorMsg = "Username is required";
      });
      return;
    }

    if (_password.text.trim().isEmpty) {
      setState(() {
        errorMsg = "Password is required";
      });
      return;
    }

    if (_password.text.trim().length < 6) {
      setState(() {
        errorMsg = "Password must be at least 6 characters";
      });
      return;
    }

    if (_password.text.trim() != _confirmPassword.text.trim()) {
      setState(() {
        errorMsg = "Passwords do not match";
      });
      return;
    }

    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() {
        errorMsg = "Valid email is required";
      });
      return;
    }

    if (_fullName.text.trim().isEmpty) {
      setState(() {
        errorMsg = "Full name is required";
      });
      return;
    }

    // Save to Hive
    box.put("username", _username.text.trim());
    box.put("password", _password.text.trim());
    box.put("email", _email.text.trim());
    box.put("fullName", _fullName.text.trim());
    box.put("biometrics", false); // Default to false
    box.put("accountCreated", DateTime.now().toIso8601String());

    // Show success dialog and navigate to login
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Account Created! 🎉'),
        content: Text('Your account has been successfully created. Please login to continue.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Login'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(24),
          children: [
            SizedBox(height: 20),

            // Logo
            Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [CupertinoColors.white, Color(0xFFAAAAAA)]
                      : [CupertinoColors.black, Color(0xFF555555)],
                ).createShader(bounds),
                child: Text(
                  'REALE\$T',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            SizedBox(height: 40),

            Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 24),

            // Full Name
            CupertinoTextField(
              controller: _fullName,
              placeholder: "Full Name",
              prefix: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.person_fill, size: 20),
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: CupertinoColors.systemGrey4, width: 1),
              ),
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 12),

            // Email
            CupertinoTextField(
              controller: _email,
              placeholder: "Email",
              keyboardType: TextInputType.emailAddress,
              prefix: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.mail, size: 20),
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: CupertinoColors.systemGrey4, width: 1),
              ),
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 12),

            // Username
            CupertinoTextField(
              controller: _username,
              placeholder: "Username",
              prefix: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.person, size: 20),
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: CupertinoColors.systemGrey4, width: 1),
              ),
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 12),

            // Password
            CupertinoTextField(
              controller: _password,
              placeholder: "Password",
              obscureText: hidePassword,
              prefix: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.lock, size: 20),
              ),
              suffix: CupertinoButton(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: CupertinoColors.systemGrey4, width: 1),
              ),
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 12),

            // Confirm Password
            CupertinoTextField(
              controller: _confirmPassword,
              placeholder: "Confirm Password",
              obscureText: hideConfirmPassword,
              prefix: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.lock_fill, size: 20),
              ),
              suffix: CupertinoButton(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  hideConfirmPassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    hideConfirmPassword = !hideConfirmPassword;
                  });
                },
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: CupertinoColors.systemGrey4, width: 1),
              ),
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            SizedBox(height: 24),

            // Error Message
            if (errorMsg.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  errorMsg,
                  style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Sign Up Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _signup,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [CupertinoColors.white, Color(0xFFDDDDDD)]
                        : [CupertinoColors.black, Color(0xFF333333)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? null : Border.all(color: CupertinoColors.systemGrey4, width: 1),
                ),
                child: Center(
                  child: Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      color: isDark ? CupertinoColors.black : CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Already have account

          ],
        ),
      ),
    );
  }
}