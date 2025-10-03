import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'add_branch_screen.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Branch> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBranches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final branches = await DatabaseHelper.instance.getAllBranches();
      
      if (mounted) {
        setState(() {
          _branches = branches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading branches: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Branches'),
            Tab(text: 'SKU Management'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Branches Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadBranches,
                  child: _branches.isEmpty
                      ? const Center(
                          child: Text('No branches found'),
                        )
                      : ListView.builder(
                          itemCount: _branches.length,
                          itemBuilder: (context, index) {
                            final branch = _branches[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                title: Text(
                                  branch.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Location: ${branch.location}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // Edit branch
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
          
          // SKU Management Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.category,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'SKU Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create and manage SKUs for your inventory',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to create SKU screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New SKU'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new branch or SKU based on current tab
          if (_tabController.index == 0) {
            // Add new branch
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddBranchScreen()),
            ).then((_) => _loadBranches()); // Refresh list after adding
          } else {
            // Add new SKU (to be implemented)
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}