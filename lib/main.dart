import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'homepage.dart';
import 'cart_page.dart';
import 'about_page.dart';
import 'orders_page.dart';
import 'signup_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  final box = await Hive.openBox("shoestore_db");

  // Initialize default values if first time
  if (box.get("isDark") == null) {
    box.put("isDark", true);
  }
  if (box.get("biometrics") == null) {
    box.put("biometrics", false);
  }

  print("Logged in user: ${box.get("username")}");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final box = Hive.box("shoestore_db");

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    bool isLoggedIn = box.get("username") != null;

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemGrey,
      ),
      home: isLoggedIn ? LoginPage() : SignupPage(),
    );
  }
}

// Login Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final box = Hive.box("shoestore_db");

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String errorMsg = "";
  bool hidePassword = true;
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    isDark = box.get("isDark", defaultValue: true);
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canAuthenticate = await auth.canCheckBiometrics ||
          await auth.isDeviceSupported();

      if (!canAuthenticate) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text("Biometrics Unavailable"),
            content: Text("Biometric authentication is not available on this device. Please ensure your device supports Face ID or fingerprint."),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        _username.text = box.get("username");
        _password.text = box.get("password");
        _login();
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text("Authentication Failed"),
            content: Text("Face ID not recognized. Please try again or use your password to login."),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text("Authentication Error"),
          content: Text("Face ID not recognized. Please try again or use your password to login."),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _login() {
    if (_username.text.trim() == box.get("username") &&
        _password.text.trim() == box.get("password")) {
      setState(() {
        errorMsg = "";
      });
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => MainApp()),
      );
    } else {
      setState(() {
        errorMsg = "Invalid username or password";
      });
    }
  }

  Future<void> _resetData() async {
    // Check if biometrics is enabled
    bool biometricsEnabled = box.get("biometrics", defaultValue: false);

    if (biometricsEnabled) {
      // Require biometric authentication first
      try {
        final bool canAuthenticate = await auth.canCheckBiometrics ||
            await auth.isDeviceSupported();

        if (!canAuthenticate) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text("Biometrics Unavailable"),
              content: Text("Biometric authentication is not available on this device. Please ensure your device supports Face ID or fingerprint."),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
          return;
        }

        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Authenticate to reset data',
          biometricOnly: true,
        );

        if (!didAuthenticate) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text("Authentication Failed"),
              content: Text("Face ID or fingerprint not recognized. Authentication is required to reset data."),
              actions: [
                CupertinoDialogAction(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
          return;
        }
      } catch (e) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text("Authentication Error"),
            content: Text("Face ID or fingerprint not recognized. Authentication is required to reset data."),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Show confirmation dialog (only after successful auth if biometrics enabled)
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Reset All Data"),
        content: Text(
            "Are you sure you want to delete all registered local data?"),
        actions: [
          CupertinoDialogAction(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Yes'),
            onPressed: () {
              Navigator.pop(context);

              // Delete all data
              box.delete("username");
              box.delete("password");
              box.delete("email");
              box.delete("fullName");
              box.delete("biometrics");
              box.delete("cartItems");
              box.delete("orderHistory");
              box.delete("accountCreated");
              box.put("isDark", true);

              // Navigate to signup page
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(builder: (context) => SignupPage()),
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
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  'Premium Footwear Collection',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
              SizedBox(height: 60),
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              SizedBox(height: 24),

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
              SizedBox(height: 24),

              // Sign In Button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _login,
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
                  ),
                  child: Center(
                    child: Text(
                      'SIGN IN',
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.black
                            : CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Biometric Login - Show only if enabled
              if (box.get("biometrics", defaultValue: false))
                Center(
                  child: CupertinoButton(
                    child: Column(
                      children: [
                        Icon(CupertinoIcons.lock_shield_fill, size: 40),
                        SizedBox(height: 4),
                        Text('Login with Biometrics',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    onPressed: _authenticateWithBiometrics,
                  ),
                ),

              // Error Message
              if (errorMsg.isNotEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      errorMsg,
                      style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              Spacer(),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Reset Data'),
                    onPressed: _resetData,
                  ),
                  // Only show Sign Up button if no user is registered
                  if (box.get("username") == null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('Sign Up'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => SignupPage()),
                        );
                      },
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

// Main App with Tab Navigation
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final box = Hive.box("shoestore_db");
  bool isDark = true;
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> orderHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      isDark = box.get("isDark", defaultValue: true);

      // Load cart items with proper type casting
      final savedCart = box.get("cartItems");
      if (savedCart != null) {
        cartItems = (savedCart as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      // Load order history with proper type casting
      final savedOrders = box.get("orderHistory");
      if (savedOrders != null) {
        orderHistory = (savedOrders as List)
            .map((order) => Map<String, dynamic>.from(order as Map))
            .toList();
      }
    });
  }

  void _saveCart() {
    box.put("cartItems", cartItems);
  }

  void _saveOrders() {
    box.put("orderHistory", orderHistory);
  }

  void addToCart(Map<String, dynamic> shoe) {
    setState(() {
      int existingIndex = cartItems.indexWhere((item) =>
      item['name'] == shoe['name'] &&
          item['selectedSize'] == shoe['selectedSize'] &&
          item['selectedColor'] == shoe['selectedColor']);

      if (existingIndex != -1) {
        cartItems[existingIndex]['quantity']++;
      } else {
        cartItems.add({...shoe, 'quantity': 1});
      }
      _saveCart();
    });
  }

  void removeFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
      _saveCart();
    });
  }

  void updateQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        cartItems.removeAt(index);
      } else {
        cartItems[index]['quantity'] = quantity;
      }
      _saveCart();
    });
  }

  void clearCart() {
    setState(() {
      cartItems.clear();
      _saveCart();
    });
  }

  void addToOrderHistory(List<Map<String, dynamic>> items, int total) {
    setState(() {
      orderHistory.insert(0, {
        'orderId': 'ORD${DateTime.now().millisecondsSinceEpoch}',
        'items': items.map((item) => Map<String, dynamic>.from(item)).toList(),
        'total': total,
        'date': DateTime.now().toIso8601String(),
        'status': 'Processing',
        'trackingNumber':
        'TRK${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'estimatedDelivery':
        DateTime.now().add(Duration(days: 3)).toIso8601String(),
        'shippingAddress': 'San Nicolas, Santa Ana, PH',
      });
      _saveOrders();
    });
  }

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
      box.put("isDark", isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        activeColor: isDark ? CupertinoColors.white : CupertinoColors.black,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(CupertinoIcons.cart),
                if (cartItems.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartItems.length}',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(CupertinoIcons.cube_box),
                if (orderHistory.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_circle),
            label: "Profile",
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return Homepage(
              onAddToCart: addToCart,
              isDark: isDark,
            );
          case 1:
            return CartPage(
              cartItems: cartItems,
              onRemoveItem: removeFromCart,
              onUpdateQuantity: updateQuantity,
              onClearCart: clearCart,
              onOrderPlaced: addToOrderHistory,
              isDark: isDark,
            );
          case 2:
            return OrdersPage(
              orders: orderHistory.map((order) {
                return {
                  ...order,
                  'date': DateTime.parse(order['date']),
                  'estimatedDelivery': DateTime.parse(order['estimatedDelivery']),
                };
              }).toList(),
              isDark: isDark,
            );
          case 3:
            return ProfilePage(
              isDark: isDark,
              onToggleTheme: toggleTheme,
            );
          default:
            return Container();
        }
      },
    );
  }
}