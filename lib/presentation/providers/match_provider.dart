import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/match.dart';
import '../../data/repositories/match_repository.dart';
import '../../domain/use_cases/match_use_cases.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

final matchUseCasesProvider = Provider<MatchUseCases>((ref) {
  final repository = ref.watch(matchRepositoryProvider);
  return MatchUseCases(repository);
});

final matchesProvider = StateNotifierProvider<MatchesNotifier, AsyncValue<List<Match>>>((ref) {
  final useCases = ref.watch(matchUseCasesProvider);
  return MatchesNotifier(useCases);
});

class MatchesNotifier extends StateNotifier<AsyncValue<List<Match>>> {
  final MatchUseCases _matchUseCases;

  MatchesNotifier(this._matchUseCases) : super(const AsyncValue.loading()) {
    loadMatches();
  }

  Future<void> loadMatches() async {
    try {
      state = const AsyncValue.loading();
      final matches = await _matchUseCases.getMatches();
      state = AsyncValue.data(matches);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addMatch(Match match) async {
    try {
      await _matchUseCases.addMatch(match);
      await loadMatches();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> editMatch(Match match) async {
    try {
      await _matchUseCases.editMatch(match);
      await loadMatches();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMatch(String id) async {
    try {
      await _matchUseCases.deleteMatch(id);
      await loadMatches();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Match?> getMatch(String id) async {
    try {
      return await _matchUseCases.getMatch(id);
    } catch (error) {
      return null;
    }
  }

  Future<List<Match>> getMatchesForPlayer(String playerName) async {
    try {
      return await _matchUseCases.getMatchesForPlayer(playerName);
    } catch (error) {
      return [];
    }
  }
}

