import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/app_database.dart';
import 'package:warehouse_inventory/screens/edit_master_item_screen.dart';

class EditBranchScreen extends StatefulWidget {
  final Branch branch;

  const EditBranchScreen({super.key, required this.branch});

  @override
  State<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends State<EditBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _codeController;
  late TextEditingController _weeklyOrderOfftakeController;
  late TextEditingController _weeklyReorderPointController;
  late TextEditingController _maintainingInventoryController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
    _locationController = TextEditingController(text: widget.branch.location);
    _codeController = TextEditingController(text: widget.branch.code ?? '');
    _weeklyOrderOfftakeController = TextEditingController(text: widget.branch.weeklyOrderOfftake ?? '');
    _weeklyReorderPointController = TextEditingController(text: widget.branch.weeklyReorderPoint ?? '');
    _maintainingInventoryController = TextEditingController(text: widget.branch.maintainingInventory ?? '');
  }

  Future<void> _updateBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new Branch object using the Drift-generated class
      final updatedBranch = Branch(
        id: widget.branch.id!,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim(),
        weeklyOrderOfftake: _weeklyOrderOfftakeController.text.trim().isEmpty
            ? null
            : _weeklyOrderOfftakeController.text.trim(),
        weeklyReorderPoint: _weeklyReorderPointController.text.trim().isEmpty
            ? null
            : _weeklyReorderPointController.text.trim(),
        maintainingInventory: _maintainingInventoryController.text.trim().isEmpty
            ? null
            : _maintainingInventoryController.text.trim(),
      );

      await AppDatabase.instance.updateBranch(updatedBranch);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating branch: ${e.toString()}'),
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

  Future<void> _deleteBranch() async {
    if (!mounted) return;

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Branch'),
          content: const Text(
              'Are you sure you want to delete this branch? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AppDatabase.instance.deleteBranch(widget.branch.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting branch: ${e.toString()}'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _codeController.dispose();
    _weeklyOrderOfftakeController.dispose();
    _weeklyReorderPointController.dispose();
    _maintainingInventoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDarkMode ? Colors.white.withValues(alpha:0.05) : Colors.white.withValues(alpha:0.1),
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
                  color: isDarkMode ? Colors.white.withValues(alpha:0.08) : Colors.white.withValues(alpha:0.15),
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
                  color: isDarkMode ? Colors.white.withValues(alpha:0.05) : Colors.white.withValues(alpha:0.1),
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
                  color: isDarkMode ? Colors.white.withValues(alpha:0.06) : Colors.white.withValues(alpha:0.12),
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
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Edit Branch',
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withValues(alpha:0.3),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[850]!.withValues(alpha:0.95) : Colors.white.withValues(alpha:0.95),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:isDarkMode ? 0.3 : 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withValues(alpha:0.3),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _nameController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Branch Name',
                                        labelStyle: TextStyle(
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.store,
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter a branch name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withValues(alpha:0.3),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _locationController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Location',
                                        labelStyle: TextStyle(
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.location_on,
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter a location';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withValues(alpha:0.3),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _codeController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Code',
                                        labelStyle: TextStyle(
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.code,
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withValues(alpha:0.3),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _weeklyOrderOfftakeController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Weekly Order Offtake',
                                        labelStyle: TextStyle(
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.shopping_cart,
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withValues(alpha:0.3),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _weeklyReorderPointController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Weekly ReOrder Point',
                                        labelStyle: TextStyle(
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.warning,
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4).withValues(alpha:0.3),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _maintainingInventoryController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Maintaining Inventory',
                                        labelStyle: TextStyle(
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.inventory,
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF0651A4),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.manage_search),
                                    label: const Text(
                                      'Edit Master Items for this Branch',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 4,
                                      shadowColor: const Color(
                                        0xFF0651A4,
                                      ).withValues(alpha:isDarkMode ? 0.5 : 0.3),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditMasterItemScreen(
                                                      branch: widget.branch,
                                                    ),
                                              ),
                                            );
                                          },
                                  ),
                                ],
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
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _isLoading ? null : _deleteBranch,
            heroTag: 'delete',
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Icon(Icons.delete),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _isLoading ? null : _updateBranch,
            heroTag: 'save',
            backgroundColor: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFF0651A4),
            foregroundColor: Colors.white,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}
