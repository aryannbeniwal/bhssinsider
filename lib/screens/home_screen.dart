import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/constants.dart';
import '../models/event.dart';
import '../models/vacancy.dart';
import '../services/database_service.dart';
import 'employees/employees_list_screen.dart';
import 'invoices/invoices_list_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const EmployeesListScreen(),
    const InvoicesListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Invoices',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _db = DatabaseService();
  List<Event> _upcomingEvents = [];
  List<Vacancy> _activeVacancies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final events = await _db.getUpcomingEvents();
    final vacancies = await _db.getActiveVacancies();

    setState(() {
      _upcomingEvents = events;
      _activeVacancies = vacancies;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyUsername);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Event Date'),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final event = Event(
                    title: titleController.text,
                    description: descriptionController.text,
                    location: locationController.text,
                    eventDate: selectedDate,
                  );
                  await _db.insertEvent(event);
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVacancyDialog() {
    final positionController = TextEditingController();
    final descriptionController = TextEditingController();
    final requirementsController = TextEditingController();
    final locationController = TextEditingController();
    final openingsController = TextEditingController();
    final salaryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vacancy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: requirementsController,
                decoration: const InputDecoration(labelText: 'Requirements'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: openingsController,
                decoration: const InputDecoration(labelText: 'No. of Openings'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Salary Range (Optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (positionController.text.isNotEmpty &&
                  openingsController.text.isNotEmpty) {
                final vacancy = Vacancy(
                  position: positionController.text,
                  description: descriptionController.text,
                  requirements: requirementsController.text,
                  location: locationController.text,
                  openings: int.parse(openingsController.text),
                  salaryRange: salaryController.text.isNotEmpty
                      ? double.parse(salaryController.text)
                      : null,
                );
                await _db.insertVacancy(vacancy);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppConstants.companyName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your security services business',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textLight.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Events
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upcoming Events',
                          style: AppTextStyles.heading3,
                        ),
                        TextButton.icon(
                          onPressed: _showAddEventDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _upcomingEvents.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No upcoming events',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _upcomingEvents.length,
                            itemBuilder: (context, index) {
                              final event = _upcomingEvents[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.event,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  title: Text(event.title),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.description),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.location,
                                            style: AppTextStyles.caption,
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.calendar_today,
                                              size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy')
                                                .format(event.eventDate),
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.error),
                                    onPressed: () async {
                                      await _db.deleteEvent(event.id!);
                                      _loadData();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),

                    // Vacancies
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Vacancies',
                          style: AppTextStyles.heading3,
                        ),
                        TextButton.icon(
                          onPressed: _showAddVacancyDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _activeVacancies.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No active vacancies',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _activeVacancies.length,
                            itemBuilder: (context, index) {
                              final vacancy = _activeVacancies[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.work,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  title: Text(vacancy.position),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(vacancy.description),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            vacancy.location,
                                            style: AppTextStyles.caption,
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.people,
                                              size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${vacancy.openings} openings',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.error),
                                    onPressed: () async {
                                      await _db.deleteVacancy(vacancy.id!);
                                      _loadData();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
