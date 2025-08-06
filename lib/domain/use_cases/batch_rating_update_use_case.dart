import 'package:csv/csv.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/player.dart';
import '../../data/models/match.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/match_repository.dart';
import 'rating_calculation_use_case.dart';

enum BatchUpdatePeriod { weekly, monthly }

class BatchRatingUpdateUseCase {
  final PlayerRepository _playerRepository;
  final MatchRepository _matchRepository;
  final RatingCalculationUseCase _ratingCalculationUseCase;

  BatchRatingUpdateUseCase(
    this._playerRepository,
    this._matchRepository,
    this._ratingCalculationUseCase,
  );

  Future<BatchUpdateResult> runWeeklyUpdate() async {
    return await _runBatchUpdate(DateTime.now().subtract(Duration(days: 7)), DateTime.now());
  }

  Future<BatchUpdateResult> runMonthlyUpdate() async {
    final startDate = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
    final endDate = DateTime(DateTime.now().year, DateTime.now().month, 0);
    return await _runBatchUpdate(startDate, endDate);
  }

  Future<BatchUpdateResult> _runBatchUpdate(DateTime startDate, DateTime endDate) async {
    
    // Get matches from the specified period that haven't been processed
    List<Match> matchesInPeriod = await _matchRepository.getMatchesByDateRange(startDate, endDate);
    List<Match> unprocessedMatches = matchesInPeriod.where((match) => !match.isRatingProcessed).toList();

    if (unprocessedMatches.isEmpty) {
      return BatchUpdateResult(
        success: true,
        message: 'No unprocessed matches found in the specified period.',
        matchesProcessed: 0,
        playersUpdated: 0,
      );
    }

    // Get all players involved in these matches
    final Set<String> playerIds = {};
    for (final match in unprocessedMatches) {
      playerIds.addAll(match.getAllPlayerIds());
    }

    final List<Player> playersToUpdate = await _playerRepository.getPlayersByIds(playerIds.toList());

    try {
      // Calculate new ratings for all affected players
      await _ratingCalculationUseCase.calculateNewRatings(playersToUpdate, unprocessedMatches);

      // Update inactive player ratings
      await _ratingCalculationUseCase.updateInactivePlayerRatings(startDate);

      return BatchUpdateResult(
        success: true,
        message: 'Batch update completed successfully.',
        matchesProcessed: unprocessedMatches.length,
        playersUpdated: playersToUpdate.length,
      );
    } catch (e) {
      return BatchUpdateResult(
        success: false,
        message: 'Batch update failed: $e',
        matchesProcessed: 0,
        playersUpdated: 0,
      );
    }
  }

  Future<BatchUpdateResult> processAllUnprocessedMatches() async {
    try {
      List<Match> unprocessedMatches = await _matchRepository.getUnprocessedMatches();
      final matchCount = unprocessedMatches.length;
      
      if (unprocessedMatches.isEmpty) {
        return BatchUpdateResult(
          success: true,
          message: 'No unprocessed matches found.',
          matchesProcessed: 0,
          playersUpdated: 0,
        );
      }

      DateTime earliestDate = unprocessedMatches
          .map((match) => match.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      DateTime latestDate = unprocessedMatches
          .map((match) => match.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      DateTime currentStart = earliestDate;

      while (currentStart.millisecondsSinceEpoch <= latestDate.millisecondsSinceEpoch) {
        DateTime currentEnd = currentStart.add(Duration(days: 6));
        if (currentEnd.isAfter(latestDate)) {
          currentEnd = latestDate;
        }

        await _runBatchUpdate(currentStart, currentEnd);
        currentStart = currentEnd.add(Duration(days: 1));

      }
      

      
      return BatchUpdateResult(
        success: true,
        message: 'All unprocessed matches have been processed.',
        matchesProcessed: matchCount,
        playersUpdated: 0, // We don't track this in this method
      );
    } catch (e) {
      return BatchUpdateResult(
        success: false,
        message: 'Failed to process unprocessed matches: $e',
        matchesProcessed: 0,
        playersUpdated: 0,
      );
    }
  }

  Future<BatchUpdateResult> resetAllMatchesAndPlayers() async {
    try {
      final allMatches = await _matchRepository.getAllMatches();
      for (final match in allMatches) {
        await _matchRepository.updateMatch(match.copyWith(isRatingProcessed: false));
      }
      final allPlayers = await _playerRepository.getAllPlayers();
      for (final player in allPlayers) {
        await _playerRepository.updatePlayer(player.copyWith(
          rating: 1500,
          ratingDeviation: 350,
          ratingChange: 0,
          lastActivityDate: DateTime.now(),
        ));
      }
      return BatchUpdateResult(
        success: true,
        message: 'Reset successful',
        matchesProcessed: allMatches.length,
        playersUpdated: allPlayers.length,
      );
    } catch (e) {
      return BatchUpdateResult(
        success: false,
        message: 'Reset failed: $e',
        matchesProcessed: 0,
        playersUpdated: 0,
      );
    }
  }

  Future<File> exportPlayersToCsv() async {
    final players = await _playerRepository.getAllPlayers();
    List<List<dynamic>> rows = [
      ['id', 'name', 'rating', 'ratingDeviation', 'side', 'lastActivityDate']
    ];
    for (final player in players) {
      rows.add([
        player.id,
        player.name,
        player.rating,
        player.ratingDeviation,
        player.side,
        player.lastActivityDate.toIso8601String(),
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/players.csv');
    return file.writeAsString(csv);
  }

  Future<File> exportMatchesToCsv() async {
    final matches = await _matchRepository.getAllMatches();
    List<List<dynamic>> rows = [
      ['id', 'date', 'team1Player1Id', 'team1Player2Id', 'team2Player1Id', 'team2Player2Id', 'team1Score', 'team2Score', 'winnerTeam', 'isRatingProcessed']
    ];
    for (final match in matches) {
      rows.add([
        match.id,
        match.date.toIso8601String(),
        (await _playerRepository.getPlayer(match.team1Player1Id))!.name,
        (await _playerRepository.getPlayer(match.team1Player2Id))!.name,
        (await _playerRepository.getPlayer(match.team2Player1Id))!.name,
        (await _playerRepository.getPlayer(match.team2Player2Id))!.name,
        match.team1Score,
        match.team2Score,
        match.winnerTeam,
        match.isRatingProcessed ? 1 : 0,
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/matches.csv');
    return file.writeAsString(csv);
  }

  Future<void> importPlayersFromCsv(File file) async {
    final csvString = await file.readAsString();
    final rows = const CsvToListConverter().convert(csvString, eol: '\n');
    for (int i = 1; i < rows.length; i++) { // skip header
      final row = rows[i];
      String id = (row[0] == null) ? '' : row[0].toString().trim();
      
      if (!Uuid.isValidUUID(fromString: id) || id.isEmpty || id.toLowerCase() == 'null') {
        id = Uuid().v4(); // Generate a new player ID if the provided one is invalid or missing
      }

      final player = Player(
        id: id,
        name: row[1]?.toString() ?? id,
        rating: row[2] is num ? row[2].toDouble() : double.tryParse(row[2].toString()) ?? 1500,
        ratingDeviation: row[3] is num ? row[3].toDouble() : double.tryParse(row[3].toString()) ?? 350,
        side: row[4]?.toString() ?? 'Both',
        lastActivityDate: DateTime.tryParse(row[5]?.toString() ?? '') ?? DateTime.fromMicrosecondsSinceEpoch(0),
      );

      await _playerRepository.addPlayer(player);
    }
  }

  Future<void> importMatchesFromCsv(File file) async {
    final csvString = await file.readAsString();
    final rows = const CsvToListConverter().convert(csvString, convertEmptyTo: '', eol: '\n');
    for (int i = 1; i < rows.length; i++) { // skip header
      final row = rows[i];
      String id = (row[0] == null) ? '' : row[0].toString().trim();
      
      if (!Uuid.isValidUUID(fromString: id) || id.isEmpty || id.toLowerCase() == 'null') {
        id = Uuid().v4(); // Always generate a new match ID if invalid, empty, or 'null'
      }
      
      final match = Match(
        id: id,
        date: DateTime.parse(row[1]),
        team1Player1Id: (await _playerRepository.getOrAddPlayerByName(row[2]))!.id,
        team1Player2Id: (await _playerRepository.getOrAddPlayerByName(row[3]))!.id,
        team2Player1Id: (await _playerRepository.getOrAddPlayerByName(row[4]))!.id,
        team2Player2Id: (await _playerRepository.getOrAddPlayerByName(row[5]))!.id,
        team1Score: row[6],
        team2Score: row[7],
        winnerTeam: row[8],
        isRatingProcessed: false,
      );
      
      await _matchRepository.addMatch(match);      
    }
  }
}

class BatchUpdateResult {
  final bool success;
  final String message;
  final int matchesProcessed;
  final int playersUpdated;

  BatchUpdateResult({
    required this.success,
    required this.message,
    required this.matchesProcessed,
    required this.playersUpdated,
  });
}

