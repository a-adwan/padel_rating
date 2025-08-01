import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class DatabaseHelper {
  static const String _databaseName = 'padel_rating.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String playersTable = 'players';
  static const String matchesTable = 'matches';

  // Player table columns
  static const String playerIdColumn = 'id';
  static const String playerNameColumn = 'name';
  static const String playerRatingColumn = 'rating';
  static const String playerRatingDeviationColumn = 'ratingDeviation';
  static const String playerLastActivityDateColumn = 'lastActivityDate';

  // Match table columns
  static const String matchIdColumn = 'id';
  static const String matchDateColumn = 'date';
  static const String matchTeam1Player1IdColumn = 'team1Player1Id';
  static const String matchTeam1Player2IdColumn = 'team1Player2Id';
  static const String matchTeam2Player1IdColumn = 'team2Player1Id';
  static const String matchTeam2Player2IdColumn = 'team2Player2Id';
  static const String matchTeam1ScoreColumn = 'team1Score';
  static const String matchTeam2ScoreColumn = 'team2Score';
  static const String matchWinnerTeamColumn = 'winnerTeam';
  static const String matchIsRatingProcessedColumn = 'isRatingProcessed';

  static Database? _database;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
		String path = '${directory.path}/$_databaseName';
    await Directory(dirname(path)).create(recursive: true); // Ensure directory exists
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Create players table
    await db.execute('''
      CREATE TABLE $playersTable (
        $playerIdColumn TEXT PRIMARY KEY,
        $playerNameColumn TEXT NOT NULL,
        $playerRatingColumn REAL NOT NULL DEFAULT 1500.0,
        $playerRatingDeviationColumn REAL NOT NULL DEFAULT 350.0,
        $playerLastActivityDateColumn INTEGER NOT NULL
      )
    ''');

    // Create matches table
    await db.execute('''
      CREATE TABLE $matchesTable (
        $matchIdColumn TEXT PRIMARY KEY,
        $matchDateColumn INTEGER NOT NULL,
        $matchTeam1Player1IdColumn TEXT NOT NULL,
        $matchTeam1Player2IdColumn TEXT NOT NULL,
        $matchTeam2Player1IdColumn TEXT NOT NULL,
        $matchTeam2Player2IdColumn TEXT NOT NULL,
        $matchTeam1ScoreColumn INTEGER NOT NULL,
        $matchTeam2ScoreColumn INTEGER NOT NULL,
        $matchWinnerTeamColumn INTEGER NOT NULL,
        $matchIsRatingProcessedColumn INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY ($matchTeam1Player1IdColumn) REFERENCES $playersTable ($playerIdColumn),
        FOREIGN KEY ($matchTeam1Player2IdColumn) REFERENCES $playersTable ($playerIdColumn),
        FOREIGN KEY ($matchTeam2Player1IdColumn) REFERENCES $playersTable ($playerIdColumn),
        FOREIGN KEY ($matchTeam2Player2IdColumn) REFERENCES $playersTable ($playerIdColumn)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_matches_date ON $matchesTable ($matchDateColumn)
    ''');

    await db.execute('''
      CREATE INDEX idx_matches_processed ON $matchesTable ($matchIsRatingProcessedColumn)
    ''');

    await db.execute('''
      CREATE INDEX idx_players_last_activity ON $playersTable ($playerLastActivityDateColumn)
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    // For now, we'll just recreate the tables
    if (oldVersion < newVersion) {
      await db.execute('DROP TABLE IF EXISTS $matchesTable');
      await db.execute('DROP TABLE IF EXISTS $playersTable');
      await _onCreate(db, newVersion);
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Delete database (for testing purposes)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

