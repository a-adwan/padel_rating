import '../../data/models/player.dart';
import '../../data/models/match.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../services/glicko_service.dart';

class RatingCalculationUseCase {
  final PlayerRepository _playerRepository;
  final MatchRepository _matchRepository;
  final GlickoService _glickoService;

  RatingCalculationUseCase(
    this._playerRepository,
    this._matchRepository,
    this._glickoService,
  );

  Future<void> calculateNewRatings(List<Player> players, List<Match> matches) async {
    // Calculate new ratings using Glicko-1 algorithm
    final updatedPlayers = _glickoService.calculateNewRatings(players, matches);

    // Update all players in the repository
    for (final player in updatedPlayers.values) {
      await _playerRepository.updatePlayer(player);
    }

    // Mark all matches as processed
    for (final match in matches) {
      await _matchRepository.markMatchAsProcessed(match.id);
    }
  }

  Future<void> processUnprocessedMatches() async {
    final unprocessedMatches = await _matchRepository.getUnprocessedMatches();
    
    if (unprocessedMatches.isEmpty) {
      return;
    }

    // Get all players involved in unprocessed matches
    final Set<String> playerIds = {};
    for (final match in unprocessedMatches) {
      playerIds.addAll(match.getAllPlayerIds());
    }

    final List<Player> playersToUpdate = await _playerRepository.getPlayersByIds(playerIds.toList());

    await calculateNewRatings(playersToUpdate, unprocessedMatches);
  }

  Future<void> updateInactivePlayerRatings(DateTime cutoffDate) async {
    final inactivePlayers = await _playerRepository.getPlayersWithInactivity(cutoffDate);

    for (final player in inactivePlayers) {
      // Apply RD increase due to inactivity using Glicko service
      final updatedPlayers = _glickoService.calculateNewRatings([player], []);
      final updatedPlayer = updatedPlayers[player.id];
      
      if (updatedPlayer != null) {
        await _playerRepository.updatePlayer(updatedPlayer);
      }
    }
  }
}

