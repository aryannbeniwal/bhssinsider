import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/invoice.dart';
import '../models/event.dart';
import '../models/vacancy.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create employees table
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT NOT NULL,
        position TEXT NOT NULL,
        salary REAL NOT NULL,
        joiningDate TEXT NOT NULL,
        isActive INTEGER NOT NULL
      )
    ''');

    // Create invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL,
        invoiceDate TEXT NOT NULL,
        invoiceTo TEXT NOT NULL,
        invoiceToAddress TEXT NOT NULL,
        sac TEXT NOT NULL,
        placeOfSupply TEXT NOT NULL,
        cgstRate REAL NOT NULL,
        sgstRate REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create invoice_items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        serialNumber INTEGER NOT NULL,
        particulars TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        rate REAL NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // Create events table
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        eventDate TEXT NOT NULL,
        location TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create vacancies table
    await db.execute('''
      CREATE TABLE vacancies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        position TEXT NOT NULL,
        description TEXT NOT NULL,
        requirements TEXT NOT NULL,
        openings INTEGER NOT NULL,
        location TEXT NOT NULL,
        salaryRange REAL,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Employee CRUD operations
  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return await db.insert('employees', employee.toMap());
  }

  Future<List<Employee>> getEmployees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('employees');
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  Future<Employee?> getEmployee(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Invoice CRUD operations
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    int invoiceId = await db.insert('invoices', invoice.toMap());

    // Insert invoice items
    for (var item in invoice.items) {
      item.invoiceId = invoiceId;
      await db.insert('invoice_items', item.toMap());
    }

    return invoiceId;
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      orderBy: 'createdAt DESC',
    );

    List<Invoice> invoices = [];
    for (var map in maps) {
      Invoice invoice = Invoice.fromMap(map);
      invoice.items = await getInvoiceItems(invoice.id!);
      invoices.add(invoice);
    }

    return invoices;
  }

  Future<Invoice?> getInvoice(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    Invoice invoice = Invoice.fromMap(maps.first);
    invoice.items = await getInvoiceItems(id);
    return invoice;
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'serialNumber ASC',
    );
    return List.generate(maps.length, (i) => InvoiceItem.fromMap(maps[i]));
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await database;

    // Update invoice
    int result = await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );

    // Delete old items
    await db.delete(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoice.id],
    );

    // Insert new items
    for (var item in invoice.items) {
      item.invoiceId = invoice.id;
      await db.insert('invoice_items', item.toMap());
    }

    return result;
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;

    // Delete invoice items first (cascade)
    await db.delete(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [id],
    );

    // Delete invoice
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Event CRUD operations
  Future<int> insertEvent(Event event) async {
    final db = await database;
    return await db.insert('events', event.toMap());
  }

  Future<List<Event>> getUpcomingEvents() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'eventDate >= ?',
      whereArgs: [now],
      orderBy: 'eventDate ASC',
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'eventDate DESC',
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<int> updateEvent(Event event) async {
    final db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Vacancy CRUD operations
  Future<int> insertVacancy(Vacancy vacancy) async {
    final db = await database;
    return await db.insert('vacancies', vacancy.toMap());
  }

  Future<List<Vacancy>> getActiveVacancies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vacancies',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Vacancy.fromMap(maps[i]));
  }

  Future<List<Vacancy>> getAllVacancies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vacancies',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Vacancy.fromMap(maps[i]));
  }

  Future<int> updateVacancy(Vacancy vacancy) async {
    final db = await database;
    return await db.update(
      'vacancies',
      vacancy.toMap(),
      where: 'id = ?',
      whereArgs: [vacancy.id],
    );
  }

  Future<int> deleteVacancy(int id) async {
    final db = await database;
    return await db.delete(
      'vacancies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get next invoice number
  Future<String> getNextInvoiceNumber() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices',
    );
    int count = result.first['count'] as int;
    return 'INV${(count + 1).toString().padLeft(6, '0')}';
  }
}
