import 'package:uuid/uuid.dart';

import '../../data/models/match.dart';
import '../../data/repositories/match_repository.dart';

class MatchUseCases {
  final MatchRepository _matchRepository;
  final Uuid _uuid = const Uuid();

  MatchUseCases(this._matchRepository);

  Future<void> addMatch(Match match) async {
    Match matchToAdd = match;
    if (match.id.isEmpty) {
      matchToAdd = match.copyWith(id: _uuid.v4());
    }
    await _matchRepository.addMatch(matchToAdd);
  }

  Future<void> editMatch(Match match) async {
    await _matchRepository.updateMatch(match);
  }

  Future<List<Match>> getMatches({DateTime? startDate, DateTime? endDate}) async {
    if (startDate != null && endDate != null) {
      return await _matchRepository.getMatchesByDateRange(startDate, endDate);
    }
    return await _matchRepository.getAllMatches();
  }

  Future<Match?> getMatch(String id) async {
    return await _matchRepository.getMatch(id);
  }

  Future<void> deleteMatch(String id) async {
    await _matchRepository.deleteMatch(id);
  }

  Future<List<Match>> getMatchesForPlayer(String playerId) async {
    return await _matchRepository.getMatchesForPlayer(playerId);
  }

  Future<List<Match>> getUnprocessedMatches() async {
    return await _matchRepository.getUnprocessedMatches();
  }

  Future<void> markMatchAsProcessed(String matchId) async {
    await _matchRepository.markMatchAsProcessed(matchId);
  }

  Future<List<Match>> getMatchesByPlayer(String playerId, {DateTime? startDate, DateTime? endDate}) async {
    return await _matchRepository.getMatchesByPlayer(playerId, startDate, endDate);
  }

  Future<int> getMatchCount() async {
    return await _matchRepository.getMatchCount();
  }

  Future<int> getUnprocessedMatchCount() async {
    return await _matchRepository.getUnprocessedMatchCount();
  }

  Future<List<Match>> getMatchesInvolvingPlayers(List<String> playerIds) async {
    return await _matchRepository.getMatchesInvolvingPlayers(playerIds);
  }
}

