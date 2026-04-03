import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FavoriteLocalService {
  static final FavoriteLocalService _instance =
      FavoriteLocalService._internal();
  factory FavoriteLocalService() => _instance;
  FavoriteLocalService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'user_local.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
            CREATE TABLE favorites (
                destinationId INTEGER PRIMARY KEY,
                isSynced INTEGER DEFAULT 0,
                isDeleted INTEGER DEFAULT 0
            )
        ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE favorites ADD COLUMN isDeleted INTEGER DEFAULT 0',
      );
    }
  }

  Future<void> addFavorite(int destinationId) async {
    final database = await db;
    await database.insert('favorites', {
      'destinationId': destinationId,
      'isSynced': 0,
      'isDeleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(int destinationId) async {
    final database = await db;
    final rows = await database.query(
      'favorites',
      columns: ['destinationId'],
      where: 'destinationId = ?',
      whereArgs: [destinationId],
    );
    if (rows.isEmpty) {
      return;
    }
    await database.update(
      'favorites',
      {'isSynced': 0, 'isDeleted': 1},
      where: 'destinationId = ?',
      whereArgs: [destinationId],
    );
  }

  Future<bool> isFavorite(int destinationId) async {
    final database = await db;
    final rows = await database.query(
      'favorites',
      where: 'destinationId = ? AND isDeleted = 0',
      whereArgs: [destinationId],
    );
    return rows.isNotEmpty;
  }

  Future<List<int>> getAllFavoriteIds() async {
    final database = await db;
    final rows = await database.query('favorites', where: 'isDeleted = 0');
    return rows.map((r) => r['destinationId'] as int).toList();
  }

  Future<List<int>> getUnsyncedAddIds() async {
    final database = await db;
    final rows = await database.query(
      'favorites',
      where: 'isSynced = 0 AND isDeleted = 0',
    );
    return rows.map((r) => r['destinationId'] as int).toList();
  }

  Future<List<int>> getUnsyncedRemoveIds() async {
    final database = await db;
    final rows = await database.query(
      'favorites',
      where: 'isSynced = 0 AND isDeleted = 1',
    );
    return rows.map((r) => r['destinationId'] as int).toList();
  }

  Future<void> markSyncedAdd(int destinationId) async {
    final database = await db;
    await database.update(
      'favorites',
      {'isSynced': 1},
      where: 'destinationId = ?',
      whereArgs: [destinationId],
    );
  }

  Future<void> markSyncedRemove(int destinationId) async {
    final database = await db;
    await database.delete(
      'favorites',
      where: 'destinationId = ? AND isDeleted = 1',
      whereArgs: [destinationId],
    );
  }

  Future<void> applyRemoteFavorites(List<int> remoteIds) async {
    final database = await db;
    final rows = await database.query('favorites');
    final remoteSet = remoteIds.toSet();

    for (final row in rows) {
      final id = row['destinationId'] as int;
      final isSynced = (row['isSynced'] as int?) ?? 0;
      final isDeleted = (row['isDeleted'] as int?) ?? 0;
      if (isSynced == 1 && isDeleted == 0 && !remoteSet.contains(id)) {
        await database.delete(
          'favorites',
          where: 'destinationId = ? AND isDeleted = 0',
          whereArgs: [id],
        );
      }
    }

    for (final id in remoteIds) {
      final existing = await database.query(
        'favorites',
        where: 'destinationId = ?',
        whereArgs: [id],
      );
      if (existing.isNotEmpty) {
        final isDeleted = (existing.first['isDeleted'] as int?) ?? 0;
        if (isDeleted == 1) {
          continue;
        }
      }
      await database.insert('favorites', {
        'destinationId': id,
        'isSynced': 1,
        'isDeleted': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
