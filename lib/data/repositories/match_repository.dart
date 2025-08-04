import 'package:sqflite/sqflite.dart';

import '../models/match.dart';
import '../database/database_helper.dart';

class MatchRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Add a new match
  Future<void> addMatch(Match match) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseHelper.matchesTable,
      match.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing match
  Future<void> updateMatch(Match match) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseHelper.matchesTable,
      match.toMap(),
      where: '${DatabaseHelper.matchIdColumn} = ?',
      whereArgs: [match.id],
    );
  }

  // Delete a match
  Future<void> deleteMatch(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseHelper.matchesTable,
      where: '${DatabaseHelper.matchIdColumn} = ?',
      whereArgs: [id],
    );
  }

  // Get a match by ID
  Future<Match?> getMatch(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.matchesTable,
      where: '${DatabaseHelper.matchIdColumn} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Match.fromMap(maps.first);
    }
    return null;
  }

  // Get all matches
  Future<List<Match>> getAllMatches() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.matchesTable,
      orderBy: '${DatabaseHelper.matchDateColumn} DESC',
    );

    return List.generate(maps.length, (i) {
      return Match.fromMap(maps[i]);
    });
  }

  // Get matches by date range
  Future<List<Match>> getMatchesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.matchesTable,
      where: '${DatabaseHelper.matchDateColumn} >= ? AND ${DatabaseHelper.matchDateColumn} <= ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: '${DatabaseHelper.matchDateColumn} DESC',
    );

    return List.generate(maps.length, (i) {
      return Match.fromMap(maps[i]);
    });
  }

  // Get matches for a specific player
  Future<List<Match>> getMatchesForPlayer(String playerName) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.matchesTable,
      where: '''
        ${DatabaseHelper.matchTeam1Player1NameColumn} = ? OR 
        ${DatabaseHelper.matchTeam1Player2NameColumn} = ? OR 
        ${DatabaseHelper.matchTeam2Player1NameColumn} = ? OR 
        ${DatabaseHelper.matchTeam2Player2NameColumn} = ?
      ''',
      whereArgs: [playerName, playerName, playerName, playerName],
      orderBy: '${DatabaseHelper.matchDateColumn} DESC',
    );

    return List.generate(maps.length, (i) {
      return Match.fromMap(maps[i]);
    });
  }

  // Get unprocessed matches
  Future<List<Match>> getUnprocessedMatches() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.matchesTable,
      where: '${DatabaseHelper.matchIsRatingProcessedColumn} = ?',
      whereArgs: [0],
      orderBy: '${DatabaseHelper.matchDateColumn} ASC',
    );

    return List.generate(maps.length, (i) {
      return Match.fromMap(maps[i]);
    });
  }

  // Mark a match as processed
  Future<void> markMatchAsProcessed(String matchId) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseHelper.matchesTable,
      {DatabaseHelper.matchIsRatingProcessedColumn: 1},
      where: '${DatabaseHelper.matchIdColumn} = ?',
      whereArgs: [matchId],
    );
  }

  // Get matches by player with optional date range
  Future<List<Match>> getMatchesByPlayer(String playerName, DateTime? startDate, DateTime? endDate) async {
    final db = await _databaseHelper.database;
    
    String whereClause = '''
      ${DatabaseHelper.matchTeam1Player1NameColumn} = ? OR 
      ${DatabaseHelper.matchTeam1Player2NameColumn} = ? OR 
      ${DatabaseHelper.matchTeam2Player1NameColumn} = ? OR 
      ${DatabaseHelper.matchTeam2Player2NameColumn} = ?
    ''';

    List<dynamic> whereArgs = [playerName, playerName, playerName, playerName];
    
    if (startDate != null) {
      whereClause += ' AND ${DatabaseHelper.matchDateColumn} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      whereClause += ' AND ${DatabaseHelper.matchDateColumn} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.matchesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseHelper.matchDateColumn} DESC',
    );

    return List.generate(maps.length, (i) {
      return Match.fromMap(maps[i]);
    });
  }

  // Get match count
  Future<int> getMatchCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.matchesTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get unprocessed match count
  Future<int> getUnprocessedMatchCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.matchesTable} WHERE ${DatabaseHelper.matchIsRatingProcessedColumn} = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get matches involving specific players
  Future<List<Match>> getMatchesInvolvingPlayers(List<String> playerNames) async {
    if (playerNames.isEmpty) return [];

    final db = await _databaseHelper.database;
    //final placeholders = List.filled(playerNames.length * 4, '?').join(',');
    final List<dynamic> whereArgs = [];
    
    // Add each player name 4 times for the 4 player positions
    for (int i = 0; i < 4; i++) {
      whereArgs.addAll(playerNames);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.matchesTable,
      where: '''
        ${DatabaseHelper.matchTeam1Player1NameColumn} IN (${List.filled(playerNames.length, '?').join(',')}) OR 
        ${DatabaseHelper.matchTeam1Player2NameColumn} IN (${List.filled(playerNames.length, '?').join(',')}) OR 
        ${DatabaseHelper.matchTeam2Player1NameColumn} IN (${List.filled(playerNames.length, '?').join(',')}) OR 
        ${DatabaseHelper.matchTeam2Player2NameColumn} IN (${List.filled(playerNames.length, '?').join(',')})
      ''',
      whereArgs: whereArgs,
      orderBy: '${DatabaseHelper.matchDateColumn} DESC',
    );

    return List.generate(maps.length, (i) {
      return Match.fromMap(maps[i]);
    });
  }
}

