import 'package:flutter/material.dart';
import 'package:warehouse_inventory/database/database_helper.dart';
import 'package:warehouse_inventory/models/branch.dart';
import 'package:warehouse_inventory/widgets/filter_widget.dart';
import 'add_branch_screen.dart';
import 'edit_branch_screen.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  List<Branch> _branches = [];
  List<Branch> _filteredBranches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
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
          _filteredBranches = branches;
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildFilterWidget(
                  filterOptions: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'location', child: Text('Location')),
                    DropdownMenuItem(value: 'code', child: Text('Code')),
                  ],
                  onFilterApplied: (filterType, filterValue) {
                    setState(() {
                      _filteredBranches = _branches.where((branch) {
                        switch (filterType) {
                          case 'name':
                            return branch.name.toLowerCase().contains(filterValue.toLowerCase());
                          case 'location':
                            return branch.location.toLowerCase().contains(filterValue.toLowerCase());
                          case 'code':
                            return branch.code?.toLowerCase().contains(filterValue.toLowerCase()) ?? false;
                          default:
                            return true;
                        }
                      }).toList();
                    });
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadBranches,
                    child: _filteredBranches.isEmpty
                        ? const Center(
                            child: Text('No branches found'),
                          )
                        : ListView.builder(
                            itemCount: _filteredBranches.length,
                            itemBuilder: (context, index) {
                              final branch = _filteredBranches[index];
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
                                  subtitle: Text(
                                    'Location: ${branch.location}${branch.code != null && branch.code!.isNotEmpty ? ', Code: ${branch.code}' : ''}',
                                  ),
                                  onTap: () async {
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditBranchScreen(branch: branch),
                                      ),
                                    );
                                    if (updated == true) {
                                      _loadBranches();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new branch
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBranchScreen()),
          ).then((_) => _loadBranches()); // Refresh list after adding
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}