import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../database/database_helper.dart';

class PlayerRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Add a new player
  Future<void> addPlayer(Player player) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseHelper.playersTable,
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing player
  Future<void> updatePlayer(Player player) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseHelper.playersTable,
      player.toMap(),
      where: '${DatabaseHelper.playerIdColumn} = ?',
      whereArgs: [player.id],
    );
  }

  // Delete a player
  Future<void> deletePlayer(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseHelper.playersTable,
      where: '${DatabaseHelper.playerIdColumn} = ?',
      whereArgs: [id],
    );
  }

  // Get a player by ID
  Future<Player?> getPlayer(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.playersTable,
      where: '${DatabaseHelper.playerIdColumn} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Player.fromMap(maps.first);
    }
    return null;
  }

  // Get a player by Name
  Future<Player?> getPlayerByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.playersTable,
      where: '${DatabaseHelper.playerNameColumn} = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      return Player.fromMap(maps.first);
    }
    return null;
  }

  // Get or add a player by Name
  Future<Player?> getOrAddPlayerByName(String name) async {
    if (await playerExistsByName(name)) {
      return await getPlayerByName(name);
    }

    // If not found, create a new player
    final newPlayer = Player(
      id: Uuid().v4(),
      name: name,
      rating: 1500,
      ratingDeviation: 350,
      lastActivityDate: DateTime.fromMicrosecondsSinceEpoch(0),
    );

    await addPlayer(newPlayer);
    
    return newPlayer;
  }

  // Get all players
  Future<List<Player>> getAllPlayers() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.playersTable,
      orderBy: '${DatabaseHelper.playerNameColumn} ASC',
    );

    return List.generate(maps.length, (i) {
      return Player.fromMap(maps[i]);
    });
  }

  // Update player rating and rating deviation
  Future<void> updatePlayerRating(String playerId, double newRating, double newRatingDeviation) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseHelper.playersTable,
      {
        DatabaseHelper.playerRatingColumn: newRating,
        DatabaseHelper.playerRatingDeviationColumn: newRatingDeviation,
        DatabaseHelper.playerLastActivityDateColumn: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseHelper.playerIdColumn} = ?',
      whereArgs: [playerId],
    );
  }

  // Get players with inactivity (last activity before cutoff date)
  Future<List<Player>> getPlayersWithInactivity(DateTime cutoffDate) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.playersTable,
      where: '${DatabaseHelper.playerLastActivityDateColumn} < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );

    return List.generate(maps.length, (i) {
      return Player.fromMap(maps[i]);
    });
  }

  // Get players by IDs
  Future<List<Player>> getPlayersByIds(List<String> playerIds) async {
    if (playerIds.isEmpty) return [];
    
    final db = await _databaseHelper.database;
    final placeholders = List.filled(playerIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.playersTable,
      where: '${DatabaseHelper.playerIdColumn} IN ($placeholders)',
      whereArgs: playerIds,
    );

    return List.generate(maps.length, (i) {
      return Player.fromMap(maps[i]);
    });
  }

  // Check if a player exists by ID
  Future<bool> playerExists(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.playersTable,
      where: '${DatabaseHelper.playerIdColumn} = ?',
      whereArgs: [id],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Check if a player exists by Name
  Future<bool> playerExistsByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.playersTable,
      where: '${DatabaseHelper.playerNameColumn} = ?',
      whereArgs: [name],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Get player count
  Future<int> getPlayerCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.playersTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

