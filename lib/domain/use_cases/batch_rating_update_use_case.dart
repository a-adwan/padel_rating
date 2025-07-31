import '../../data/models/player.dart';
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
    return await _runBatchUpdate(BatchUpdatePeriod.weekly);
  }

  Future<BatchUpdateResult> runMonthlyUpdate() async {
    return await _runBatchUpdate(BatchUpdatePeriod.monthly);
  }

  Future<BatchUpdateResult> _runBatchUpdate(BatchUpdatePeriod period) async {
    final now = DateTime.now();
    final DateTime startDate;

    switch (period) {
      case BatchUpdatePeriod.weekly:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case BatchUpdatePeriod.monthly:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    // Get matches from the specified period that haven't been processed
    final matchesInPeriod = await _matchRepository.getMatchesByDateRange(startDate, now);
    final unprocessedMatches = matchesInPeriod.where((match) => !match.isRatingProcessed).toList();

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
      await _ratingCalculationUseCase.updateInactivePlayerRatings();

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
      final unprocessedMatches = await _matchRepository.getUnprocessedMatches();
      final matchCount = unprocessedMatches.length;
      
      await _ratingCalculationUseCase.processUnprocessedMatches();
      await _ratingCalculationUseCase.updateInactivePlayerRatings();
      
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

