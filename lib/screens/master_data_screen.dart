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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0651A4), Color(0xFF0A7BFF), Color(0xFF42A5F5)],
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
                  color: Colors.white.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.15),
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
                  color: Colors.white.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.12),
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Master Data',
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0651A4),
                              ),
                            )
                          : Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0651A4),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.business,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Branches',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AddBranchScreen(),
                                            ),
                                          ).then((_) => _loadBranches());
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Branch'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Color(0xFF0651A4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          elevation: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: buildFilterWidget(
                                    filterOptions: const [
                                      DropdownMenuItem(
                                        value: 'name',
                                        child: Text('Name'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'location',
                                        child: Text('Location'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'code',
                                        child: Text('Code'),
                                      ),
                                    ],
                                    onFilterApplied: (filterType, filterValue) {
                                      setState(() {
                                        _filteredBranches = _branches.where((
                                          branch,
                                        ) {
                                          switch (filterType) {
                                            case 'name':
                                              return branch.name
                                                  .toLowerCase()
                                                  .contains(
                                                    filterValue.toLowerCase(),
                                                  );
                                            case 'location':
                                              return branch.location
                                                  .toLowerCase()
                                                  .contains(
                                                    filterValue.toLowerCase(),
                                                  );
                                            case 'code':
                                              return branch.code
                                                      ?.toLowerCase()
                                                      .contains(
                                                        filterValue
                                                            .toLowerCase(),
                                                      ) ??
                                                  false;
                                            default:
                                              return true;
                                          }
                                        }).toList();
                                      });
                                    },
                                    onReset: () {
                                      setState(() {
                                        _filteredBranches = List.from(
                                          _branches,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RefreshIndicator(
                                    onRefresh: _loadBranches,
                                    child: _filteredBranches.isEmpty
                                        ? const Center(
                                            child: Text('No branches found'),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            itemCount: _filteredBranches.length,
                                            itemBuilder: (context, index) {
                                              final branch =
                                                  _filteredBranches[index];
                                              return Card(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12.0,
                                                ),
                                                elevation: 6,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                color: Colors.white,
                                                shadowColor: const Color(
                                                  0xFF0651A4,
                                                ).withOpacity(0.2),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        const Color(
                                                          0xFF0651A4,
                                                        ).withOpacity(0.1),
                                                    child: const Icon(
                                                      Icons.business,
                                                      color: Color(0xFF0651A4),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    branch.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF0651A4),
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    'Location: ${branch.location}${branch.code != null && branch.code!.isNotEmpty ? '\nCode: ${branch.code}' : ''}',
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  onTap: () async {
                                                    final updated =
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                EditBranchScreen(
                                                                  branch:
                                                                      branch,
                                                                ),
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
