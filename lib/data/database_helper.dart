import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('subguard.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // Current Production Schema Version
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        cost REAL NOT NULL,
        currency TEXT NOT NULL,
        billingCycle TEXT NOT NULL,
        nextBillingDate TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration Architecture: Execute schema changes sequentially based on version
    if (oldVersion < 2) {
      // Example for future V2: await db.execute('ALTER TABLE subscriptions ADD COLUMN category TEXT;');
    }
  }

  Future<void> insertSubscription(Subscription sub) async {
    final db = await instance.database;
    await db.insert('subscriptions', sub.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await instance.database;
    final result = await db.query('subscriptions');
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  Future<void> updateSubscription(Subscription sub) async {
    final db = await instance.database;
    await db.update(
      'subscriptions',
      sub.toMap(),
      where: 'id = ?',
      whereArgs: [sub.id],
    );
  }

  Future<void> deleteSubscription(String id) async {
    final db = await instance.database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }
}
