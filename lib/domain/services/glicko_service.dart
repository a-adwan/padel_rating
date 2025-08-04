import 'dart:math';

import '../../data/models/player.dart';
import '../../data/models/match.dart';

class GlickoService {
  static const double _q = 0.006666666666666667; // ln(10) / 400
  static const double _c = 67.9366220487; // Calculated from 350 = sqrt(50^2 + 26c^2)
  static const double _unratedRD = 350.0;

  // Step 1: Determine ratings deviation (RD) for inactivity
  double _calculateRdForInactivity(double oldRd, DateTime lastActivityDate) {
    final now = DateTime.now();
    final daysInactive = now.difference(lastActivityDate).inDays;
    final t = daysInactive / 7.0; // Assuming 1 rating period = 1 week

    final newRd = sqrt(pow(oldRd, 2) + pow(_c, 2) * t);
    return min(newRd, _unratedRD);
  }

  // Helper function g(RD)
  double _g(double rd) {
    return 1.0 / sqrt(1.0 + 3.0 * pow(_q, 2) * pow(rd, 2) / pow(pi, 2));
  }

  // Helper function E(s|r0, RD_i)
  double _e(double r0, double ri, double gRd) {
    return 1.0 / (1.0 + pow(10.0, -gRd * (r0 - ri) / 400.0));
  }

  // Calculate new ratings for a list of players based on a list of matches
  Map<String, Player> calculateNewRatings(List<Player> players, List<Match> matches) {
    final Map<String, Player> updatedPlayers = {};
    final Map<String, Player> tempPlayers = {};

    // Build a map of playerName -> last match date
    final Map<String, DateTime> lastMatchDateMap = {};
    for (var match in matches) {
      for (var playerName in match.getAllPlayerNames()) {
        final currentDate = lastMatchDateMap[playerName];
        if (currentDate == null || match.date.isAfter(currentDate)) {
          lastMatchDateMap[playerName] = match.date;
        }
      }
    }

    // Step 1: Apply inactivity RD using last match date
    for (var player in players) {
      final lastMatchDate = lastMatchDateMap[player.name] ?? player.lastActivityDate;
      updatedPlayers[player.name] = player.copyWith(
        ratingDeviation: _calculateRdForInactivity(player.ratingDeviation, lastMatchDate),
      );
    }

    // Group matches by player for easier processing
    final Map<String, List<Match>> playerMatches = {};
    for (var match in matches) {
      for (var playerName in match.getAllPlayerNames()) {
        playerMatches.putIfAbsent(playerName, () => []).add(match);
      }
    }

    // Step 2: Calculate new ratings/deviations, but don't update yet
    for (var player in players) {
      final List<Match> relevantMatches = playerMatches[player.name] ?? [];

      if (relevantMatches.isEmpty) {
        tempPlayers[player.name] = updatedPlayers[player.name]!;
        continue;
      }

      double dSquaredInverseSum = 0.0;
      double sumGsE = 0.0;
      double ratingChange = 0.0;

      for (var match in relevantMatches) {
        // For doubles, we need to consider the average rating of the opposing team
        // and the outcome for the individual player.

        List<String> opponentNames = match.getOpponentNames(player.name);
        if (opponentNames.length != 2) {
          // This should not happen in doubles, but as a safeguard
          continue;
        }

        // Calculate average rating and RD of the opposing team
        double opponentTeamRating = 0.0;
        double opponentTeamRd = 0.0;
        for (var oppName in opponentNames) {
          final oppPlayer = updatedPlayers[oppName];
          if (oppPlayer != null) {
            opponentTeamRating += oppPlayer.rating;
            opponentTeamRd += pow(oppPlayer.ratingDeviation, 2);
          }
        }
        opponentTeamRating /= 2.0;
        opponentTeamRd = sqrt(opponentTeamRd / 2.0); // Average RD for the team

        final gRdOpponent = _g(opponentTeamRd);
        final expectedScore = _e(player.rating, opponentTeamRating, gRdOpponent);

        final actualScore = match.didPlayerWin(player.name);  // Simplified for win/loss

        dSquaredInverseSum += pow(gRdOpponent, 2) * expectedScore * (1.0 - expectedScore);
        sumGsE += gRdOpponent * (actualScore - expectedScore);
      }

      if (dSquaredInverseSum == 0) {
        tempPlayers[player.name] = updatedPlayers[player.name]!;
        continue;
      }

      final dSquared = 1.0 / (pow(_q, 2) * dSquaredInverseSum);

      // Step 2: Determine new rating
      final newRating = player.rating + (_q / (1.0 / pow(player.ratingDeviation, 2) + 1.0 / dSquared)) * sumGsE;
      ratingChange += (_q / (1.0 / pow(player.ratingDeviation, 2) + 1.0 / dSquared)) * sumGsE;

      // Step 3: Determine new ratings deviation
      final newRatingDeviation = sqrt(1.0 / (1.0 / pow(player.ratingDeviation, 2) + 1.0 / dSquared));

      tempPlayers[player.name] = player.copyWith(
        rating: newRating,
        ratingDeviation: newRatingDeviation,
        ratingChange: ratingChange,
        lastActivityDate: lastMatchDateMap[player.name],
      );
    }

    // Step 3: Apply all changes at once
    return tempPlayers;
  }
}

