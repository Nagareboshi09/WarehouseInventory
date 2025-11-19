import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:warehouse_inventory/screens/home_screen.dart';
import 'package:warehouse_inventory/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if passwords match
        if (_passwordController.text != _confirmPasswordController.text) {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Check password strength
        if (_passwordController.text.length < 6) {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password must be at least 6 characters long'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Register the user
        final user = await AppDatabase.instance.registerUser(
          _usernameController.text.trim(),
          _passwordController.text,
          role: 'user', // Default role for new users
        );

        if (user != null) {
          if (!mounted) return;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in with your credentials.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate back to login screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          if (!mounted) return;

          // Show error message (username already exists)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username already exists. Please choose a different username.'),
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
                            Icons.person_add,
                            size: 80,
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Create Account',
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
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Color(0xFF0651A4),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your account to get started',
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
                                      return 'Please enter a username';
                                    }
                                    if (value.length < 3) {
                                      return 'Username must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _emailController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Email (Optional)',
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
                                      Icons.email,
                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
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
                                            _isPasswordVisible = !_isPasswordVisible;
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
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
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
                                      Icons.lock_person,
                                      color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                    ),
                                    suffixIcon: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: isDarkMode ? Colors.white70 : Color(0xFF0651A4),
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
                                  obscureText: !_isConfirmPasswordVisible,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
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
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Color(0xFF0651A4),
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