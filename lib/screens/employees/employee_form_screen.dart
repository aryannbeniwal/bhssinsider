import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../models/employee.dart';
import '../../services/database_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _positionController;
  late TextEditingController _salaryController;

  DateTime _joiningDate = DateTime.now();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _emailController = TextEditingController(text: widget.employee?.email ?? '');
    _addressController = TextEditingController(text: widget.employee?.address ?? '');
    _positionController = TextEditingController(text: widget.employee?.position ?? '');
    _salaryController = TextEditingController(
      text: widget.employee?.salary.toString() ?? '',
    );

    if (widget.employee != null) {
      _joiningDate = widget.employee!.joiningDate;
      _isActive = widget.employee!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _joiningDate) {
      setState(() {
        _joiningDate = picked;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final employee = Employee(
          id: widget.employee?.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          position: _positionController.text.trim(),
          salary: double.parse(_salaryController.text.trim()),
          joiningDate: _joiningDate,
          isActive: _isActive,
        );

        if (widget.employee == null) {
          await _db.insertEmployee(employee);
        } else {
          await _db.updateEmployee(employee);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.employee == null
                    ? 'Employee added successfully'
                    : 'Employee updated successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Employment Details',
                        style: AppTextStyles.heading4,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _positionController,
                        decoration: InputDecoration(
                          labelText: 'Position *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter position';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _salaryController,
                        decoration: InputDecoration(
                          labelText: 'Salary *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter salary';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Joining Date *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd MMM yyyy').format(_joiningDate)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active Employee'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeTrackColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEmployee,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textLight,
                          ),
                        ),
                      )
                    : Text(
                        widget.employee == null ? 'Add Employee' : 'Update Employee',
                        style: AppTextStyles.button,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
