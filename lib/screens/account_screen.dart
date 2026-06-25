import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:warehouse_inventory/screens/home_screen.dart';
import 'package:warehouse_inventory/utils/user_helper.dart';

class AccountScreen extends StatefulWidget {
  final User? editUser;

  const AccountScreen({super.key, this.editUser});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _roleController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<String> _availableRoles = ['user', 'admin'];
  String _selectedRole = 'user';

  // Admin user management
  List<User> _allUsers = [];
  bool _isAdmin = false;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    if (widget.editUser != null) {
      _loadEditData();
    }
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = await UserHelper.getCurrentUser();
    setState(() {
      _isAdmin = currentUser?['role'] == 'admin';
    });
    
    if (_isAdmin) {
      _loadAllUsers();
    }
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await AppDatabase.instance.getAllUsers();
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  Future<void> _loadEditData() async {
    if (widget.editUser == null) return;

    setState(() {
      _usernameController.text = widget.editUser!.username;
      _roleController.text = widget.editUser!.role;
      _selectedRole = widget.editUser!.role;
    });
  }

  Future<void> _deleteUser(User user) async {
    final currentUser = await UserHelper.getCurrentUser();
    if (currentUser?['username'] == user.username) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot delete your own account'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete User',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete user "${user.username}"? This action cannot be undone.',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success = await AppDatabase.instance.deleteUser(user.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User "${user.username}" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _loadAllUsers(); // Refresh the list
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete user'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editUser(User user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AccountScreen(editUser: user),
      ),
    );
  }

  Future<void> _submitAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.editUser != null) {
        // Edit existing user
        final updatedUser = await AppDatabase.instance.updateUserRole(
          widget.editUser!.id,
          _selectedRole,
        );

        if (mounted) {
          _showSuccessDialog('User updated successfully!', false);
        }
      } else {
        // Create new user
        if (_passwordController.text != _confirmPasswordController.text) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passwords do not match'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (_passwordController.text.length < 6) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password must be at least 6 characters'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final user = await AppDatabase.instance.registerUser(
          _usernameController.text.trim(),
          _passwordController.text,
          role: _selectedRole,
        );

        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Username already exists. Please choose another.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (mounted) {
          _showSuccessDialog('Account created successfully!', true);
          if (_isAdmin) {
            _loadAllUsers(); // Refresh user list for admin users
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${widget.editUser != null ? 'updating' : 'creating'} account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message, bool isNewAccount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Success!',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF0651A4),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                
                if (isNewAccount) {
                  // For new accounts, go to dashboard
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialIndex: 0),
                    ),
                  );
                } else {
                  // For account updates, go back to account management (for admins) or refresh current view
                  if (_isAdmin) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AccountScreen(),
                      ),
                    );
                  }
                  // For non-admin users or if not admin, just stay on current screen (dismiss dialog)
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                isNewAccount ? 'Continue' : 'OK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Reset form if creating new account
    if (isNewAccount) {
      _formKey.currentState!.reset();
      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _selectedRole = 'user';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D), const Color(0xFF3A3A3A)]
                : [const Color(0xFF0651A4), const Color(0xFF0A7BFF), const Color(0xFF42A5F5)],
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
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(initialIndex: 0),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.editUser != null ? 'Edit Account' : 'Create Account',
                            style: TextStyle(
                              fontSize: 28.0,
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
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                      child: Column(
                        children: [
                          // Account Creation/Edit Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? (Colors.grey[850] ?? Colors.grey).withOpacity(0.95) : Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.person_add,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  widget.editUser != null ? 'Edit Account' : 'Account Details',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Username TextField
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withOpacity(0.3),
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _usernameController,
                                            enabled: widget.editUser == null, // Cannot change username when editing
                                            decoration: InputDecoration(
                                              labelText: 'Username *',
                                              labelStyle: TextStyle(
                                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.person,
                                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Please enter a username';
                                              }
                                              if (value.length < 3) {
                                                return 'Username must be at least 3 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Password TextField
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withOpacity(0.3),
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            decoration: InputDecoration(
                                              labelText: widget.editUser != null ? 'New Password (optional)' : 'Password *',
                                              labelStyle: TextStyle(
                                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.lock,
                                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword = !_obscurePassword;
                                                  });
                                                },
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (widget.editUser == null) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter a password';
                                                }
                                                if (value.length < 6) {
                                                  return 'Password must be at least 6 characters';
                                                }
                                              } else if (value != null && value.isNotEmpty && value.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Confirm Password TextField
                                        if (widget.editUser == null) ...[
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withOpacity(0.3),
                                              ),
                                            ),
                                            child: TextFormField(
                                              controller: _confirmPasswordController,
                                              obscureText: _obscureConfirmPassword,
                                              decoration: InputDecoration(
                                                labelText: 'Confirm Password *',
                                                labelStyle: TextStyle(
                                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.lock_outline,
                                                  color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                                    color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                                    });
                                                  },
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please confirm your password';
                                                }
                                                if (value != _passwordController.text) {
                                                  return 'Passwords do not match';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        // Role Dropdown
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withOpacity(0.3),
                                            ),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedRole,
                                            decoration: InputDecoration(
                                              labelText: 'Role *',
                                              labelStyle: TextStyle(
                                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.security,
                                                color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                            items: _availableRoles.map((String role) {
                                              return DropdownMenuItem<String>(
                                                value: role,
                                                child: Text(
                                                  role.toUpperCase(),
                                                  style: TextStyle(
                                                    color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedRole = newValue!;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please select a role';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Submit Button
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _submitAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
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
                                    ).withOpacity(isDarkMode ? 0.5 : 0.3),
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.person_add),
                                  label: Text(
                                    _isLoading ? 'Submitting...' : (widget.editUser != null ? 'Update Account' : 'Create Account'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // User List for Admin Users (only show for admin users and when not editing)
                          if (_isAdmin && widget.editUser == null) ...[
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? (Colors.grey[850] ?? Colors.grey).withOpacity(0.95) : Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.people,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'User Management',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (_isLoadingUsers)
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    if (_isLoadingUsers)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (_allUsers.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32.0),
                                          child: Text('No users found'),
                                        ),
                                      )
                                    else
                                      ..._allUsers.map((user) {
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: user.role == 'admin' 
                                                  ? Colors.orange 
                                                  : Colors.blue,
                                              child: Icon(
                                                user.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(
                                              user.username,
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Role: ${user.role.toUpperCase()}',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  onPressed: () => _editUser(user),
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                                  ),
                                                  tooltip: 'Edit User',
                                                ),
                                                IconButton(
                                                  onPressed: () => _deleteUser(user),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip: 'Delete User',
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}