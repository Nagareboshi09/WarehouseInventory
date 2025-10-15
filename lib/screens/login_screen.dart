import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await DatabaseHelper.instance.getUser(
          _usernameController.text,
          _passwordController.text,
        );

        if (user != null) {
          // Save login state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', user.username);
          await prefs.setString('role', user.role);

          if (!mounted) return;

          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          if (!mounted) return;

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid username or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF1E1E1E), Color(0xFF2D2D2D), Color(0xFF3A3A3A)]
                : [Color(0xFF0651A4), Color(0xFF0A7BFF), Color(0xFF42A5F5)],
          ),
        ),
        child: Stack(
          children: [
            // Background bubbles
            Positioned(
              top: 100,
              left: 50,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 200,
              right: 80,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              left: 100,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 250,
              right: 50,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Icon(
                            Icons.inventory,
                            size: 80,
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Warehouse Inventory',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        color: isDarkMode ? Colors.grey[850]!.withOpacity(0.95) : Colors.white.withOpacity(0.95),
                        shadowColor: const Color(0xFF0651A4).withOpacity(isDarkMode ? 0.5 : 0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to your account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white70 : Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _usernameController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your username';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                    ),
                                    suffixIcon: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                        splashRadius: 24,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Color(0xFF1E3A5F) : Color(0xFF0651A4),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 6,
                                    shadowColor: const Color(
                                      0xFF0651A4,
                                    ).withOpacity(isDarkMode ? 0.5 : 0.4),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
