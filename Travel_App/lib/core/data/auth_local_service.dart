import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AuthLocalService {
  static final AuthLocalService _instance = AuthLocalService._internal();
  factory AuthLocalService() => _instance;
  AuthLocalService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'auth_local.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
            CREATE TABLE user_session (
                uid TEXT PRIMARY KEY,
                email TEXT,
                displayName TEXT,
                provider TEXT,
                photoUrl TEXT
            )
        ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE user_session ADD COLUMN photoUrl TEXT',
      );
    }
  }

  Future<void> saveUser({
    required String uid,
    required String email,
    required String displayName,
    required String provider,
    String? photoUrl,
  }) async {
    final database = await db;
    await database.insert('user_session', {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'provider': provider,
      'photoUrl': photoUrl ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final database = await db;
    final rows = await database.query('user_session', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> clear() async {
    final database = await db;
    await database.delete('user_session');
  }
}
