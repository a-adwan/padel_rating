import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/glicko_service.dart';
import '../../domain/use_cases/rating_calculation_use_case.dart';
import '../../domain/use_cases/batch_rating_update_use_case.dart';
import 'player_provider.dart';
import 'match_provider.dart';

final glickoServiceProvider = Provider<GlickoService>((ref) {
  return GlickoService();
});

final ratingCalculationUseCaseProvider = Provider<RatingCalculationUseCase>((ref) {
  final playerRepository = ref.watch(playerRepositoryProvider);
  final matchRepository = ref.watch(matchRepositoryProvider);
  final glickoService = ref.watch(glickoServiceProvider);
  
  return RatingCalculationUseCase(
    playerRepository,
    matchRepository,
    glickoService,
  );
});

final batchRatingUpdateUseCaseProvider = Provider<BatchRatingUpdateUseCase>((ref) {
  final playerRepository = ref.watch(playerRepositoryProvider);
  final matchRepository = ref.watch(matchRepositoryProvider);
  final ratingCalculationUseCase = ref.watch(ratingCalculationUseCaseProvider);
  
  return BatchRatingUpdateUseCase(
    playerRepository,
    matchRepository,
    ratingCalculationUseCase,
  );
});

final batchUpdateStateProvider = StateNotifierProvider<BatchUpdateNotifier, BatchUpdateState>((ref) {
  final batchUpdateUseCase = ref.watch(batchRatingUpdateUseCaseProvider);
  return BatchUpdateNotifier(batchUpdateUseCase, ref);
});

class BatchUpdateNotifier extends StateNotifier<BatchUpdateState> {
  final BatchRatingUpdateUseCase _batchUpdateUseCase;
  final Ref _ref;

  BatchUpdateNotifier(this._batchUpdateUseCase, this._ref) : super(BatchUpdateState.idle());

  Future<void> runWeeklyUpdate() async {
    state = BatchUpdateState.loading();
    try {
      final result = await _batchUpdateUseCase.runWeeklyUpdate();
      state = BatchUpdateState.completed(result);
      // Refresh data after successful update
      if (result.success) {
        _ref.read(playersProvider.notifier).loadPlayers();
        _ref.read(matchesProvider.notifier).loadMatches();
      }
    } catch (e) {
      state = BatchUpdateState.error('Weekly update failed: $e');
    }
  }

  Future<void> runMonthlyUpdate() async {
    state = BatchUpdateState.loading();
    try {
      final result = await _batchUpdateUseCase.runMonthlyUpdate();
      state = BatchUpdateState.completed(result);
      // Refresh data after successful update
      if (result.success) {
        _ref.read(playersProvider.notifier).loadPlayers();
        _ref.read(matchesProvider.notifier).loadMatches();
      }
    } catch (e) {
      state = BatchUpdateState.error('Monthly update failed: $e');
    }
  }

  Future<void> processAllUnprocessedMatches() async {
    state = BatchUpdateState.loading();
    try {
      final result = await _batchUpdateUseCase.processAllUnprocessedMatches();
      state = BatchUpdateState.completed(result);
      // Refresh data after successful update
      if (result.success) {
        _ref.read(playersProvider.notifier).loadPlayers();
        _ref.read(matchesProvider.notifier).loadMatches();
      }
    } catch (e) {
      state = BatchUpdateState.error('Processing unprocessed matches failed: $e');
    }
  }

  void resetState() {
    state = BatchUpdateState.idle();
  }
}

class BatchUpdateState {
  final bool isLoading;
  final bool isCompleted;
  final bool hasError;
  final String? errorMessage;
  final BatchUpdateResult? result;

  BatchUpdateState._({
    required this.isLoading,
    required this.isCompleted,
    required this.hasError,
    this.errorMessage,
    this.result,
  });

  factory BatchUpdateState.idle() {
    return BatchUpdateState._(
      isLoading: false,
      isCompleted: false,
      hasError: false,
    );
  }

  factory BatchUpdateState.loading() {
    return BatchUpdateState._(
      isLoading: true,
      isCompleted: false,
      hasError: false,
    );
  }

  factory BatchUpdateState.completed(BatchUpdateResult result) {
    return BatchUpdateState._(
      isLoading: false,
      isCompleted: true,
      hasError: false,
      result: result,
    );
  }

  factory BatchUpdateState.error(String message) {
    return BatchUpdateState._(
      isLoading: false,
      isCompleted: false,
      hasError: true,
      errorMessage: message,
    );
  }
}

