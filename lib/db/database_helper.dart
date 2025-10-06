import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String _userTable = 'users';
  static const String _taskTable = 'tasks';
  static const String _sessionKey = 'currentUserId';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB("app.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Asegúrate de que el número de versión es correcto.
    // Si incrementas la versión, se llamará a onUpgrade.
    return await openDatabase(
      path,
      version: 2, // Mantén la versión 2
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Esta migración es correcta para añadir 'is_completed' a 'tasks'.
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE $_taskTable ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0;',
        );
      } catch (e) {
        print("Error al migrar la DB (tasks): $e");
      }
      
      // Si la versión anterior a la 2 no tenía 'passwordHash' en users,
      // y la base de datos se creó antes de que agregaras passwordHash, 
      // DEBERÍAS haber añadido esta migración.
      // Pero la solución más fácil es forzar la recreación (ver abajo).
    }
  }

  Future _createDB(Database db, int version) async {
    // *** Estructura correcta que incluye 'passwordHash' ***
    await db.execute('''
      CREATE TABLE $_userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL 
      )
    ''');

    // Tabla de tareas (correcta)
    await db.execute('''
      CREATE TABLE $_taskTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_userTable (id) ON DELETE CASCADE
      )
    ''');

    // Usuario inicial de prueba
    final passwordHash = _hashPassword("1234");
    await db.insert(_userTable, {"username": "admin", "passwordHash": passwordHash});
  }

  // -------------------- USUARIOS --------------------
  
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // La lógica de registro es correcta.
  Future<int> register(String username, String password) async {
    final db = await instance.database;
    final passwordHash = _hashPassword(password);

    final existing = await db.query(
      _userTable,
      where: "username = ?",
      whereArgs: [username],
    );
    if (existing.isNotEmpty) return -1;

    // EL ERROR OCURRÍA AQUÍ porque la DB no tenía 'passwordHash'.
    return await db.insert(_userTable, {"username": username, "passwordHash": passwordHash});
  }
  
  // (Resto de métodos loginy tareas...)
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await instance.database;
    final passwordHash = _hashPassword(password);

    final result = await db.query(
      _userTable,
      where: "username = ? AND passwordHash = ?",
      whereArgs: [username, passwordHash],
    );

    if (result.isNotEmpty) {
      final user = result.first;
      await _saveSession(user['id'] as int);
      return user;
    }
    return null;
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, userId);
  }

  Future<int?> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // -------------------- TAREAS --------------------
  
  Future<int> addTask(String title, String description, String date, int userId) async {
    final db = await instance.database;
    return await db.insert(_taskTable, {
      "title": title,
      "description": description,
      "date": date,
      "user_id": userId,
      "is_completed": 0,
    });
  }

  Future<List<Map<String, dynamic>>> getTasks(int userId) async {
    final db = await instance.database;
    return await db.query(
      _taskTable,
      where: "user_id = ?",
      whereArgs: [userId],
      orderBy: "is_completed ASC, id DESC",
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(_taskTable, where: "id = ?", whereArgs: [id]);
  }

  Future<int> updateTaskStatus(int id, int status) async {
    final db = await instance.database;
    return await db.update(_taskTable, {'is_completed': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTask(int id, String title, String description, String date) async {
    final db = await instance.database;
    return await db.update(
      _taskTable,
      {
        'title': title,
        'description': description,
        'date': date,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}