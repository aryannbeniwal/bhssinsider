import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';
import 'employee_form_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final DatabaseService _db = DatabaseService();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    final employees = await _db.getEmployees();

    setState(() {
      _employees = employees;
      _filteredEmployees = employees;
      _isLoading = false;
    });
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees
            .where((employee) =>
                employee.name.toLowerCase().contains(query.toLowerCase()) ||
                employee.position.toLowerCase().contains(query.toLowerCase()) ||
                employee.phone.contains(query))
            .toList();
      }
    });
  }

  void _navigateToEmployeeForm([Employee? employee]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeFormScreen(employee: employee),
      ),
    );

    if (result == true) {
      _loadEmployees();
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteEmployee(employee.id!);
      _loadEmployees();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employees'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterEmployees,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Employee list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No employees found'
                                  : 'No matching employees',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEmployees,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = _filteredEmployees[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: employee.isActive
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  child: Text(
                                    employee.name[0].toUpperCase(),
                                    style: AppTextStyles.heading4.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  employee.name,
                                  style: AppTextStyles.heading4,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(employee.position),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          employee.phone,
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Joined: ${DateFormat('dd MMM yyyy').format(employee.joiningDate)}',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              size: 20, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Delete',
                                              style: TextStyle(color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _navigateToEmployeeForm(employee);
                                    } else if (value == 'delete') {
                                      _deleteEmployee(employee);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEmployeeForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textLight),
      ),
    );
  }
}
