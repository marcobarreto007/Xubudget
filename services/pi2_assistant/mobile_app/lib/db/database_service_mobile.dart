// WHY: Mobile/desktop implementation using SQLCipher (sqflite_sqlcipher)
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  static const String _dbName = 'xubudget.db';
  static const String _tableName = 'expenses';
  static const _secureStorage = FlutterSecureStorage();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
    }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Get or generate database password
    String? password = await _secureStorage.read(key: 'db_password');
    if (password == null) {
      password = DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.write(key: 'db_password', value: password);
    }

    return await openDatabase(
      path,
      version: 1,
      password: password,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        source TEXT NOT NULL,
        receiptImageHash TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(_tableName, expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'date DESC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
