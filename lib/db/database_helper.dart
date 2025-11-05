import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cyrus.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');
  }

  //Enkripsi pw
  String _encrypt(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  //Register
  Future<int> registerUser(String username, String password) async {
    final db = await instance.database;
    final encryptedPassword = _encrypt(password);
    return await db.insert(
      'users',
      {
        'username': username,
        'password': encryptedPassword,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //Login
  Future<bool> loginUser(String username, String password) async {
    final db = await instance.database;
    final encryptedPassword = _encrypt(password);
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, encryptedPassword],
    );
    return result.isNotEmpty;
  }
}
