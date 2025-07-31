import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/rating_provider.dart';
import '../providers/player_provider.dart';
import '../providers/match_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchUpdateState = ref.watch(batchUpdateStateProvider);
    final playersAsyncValue = ref.watch(playersProvider);
    final matchesAsyncValue = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Rating Updates'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    playersAsyncValue.when(
                      loading: () => const Text('Loading players...'),
                      error: (error, stackTrace) => Text('Error loading players: $error'),
                      data: (players) => Text('Total Players: ${players.length}'),
                    ),
                    matchesAsyncValue.when(
                      loading: () => const Text('Loading matches...'),
                      error: (error, stackTrace) => Text('Error loading matches: $error'),
                      data: (matches) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Matches: ${matches.length}'),
                          Text('Unprocessed Matches: ${matches.where((m) => !m.isRatingProcessed).length}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Batch Update Section
            const Text(
              'Rating Updates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these options to update player ratings based on match results. '
              'Weekly updates process matches from the last 7 days, while monthly '
              'updates process matches from the last month.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Update Buttons
            if (batchUpdateState.isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing ratings...'),
                  ],
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(batchUpdateStateProvider.notifier).processAllUnprocessedMatches();
                  },
                  icon: const Icon(Icons.update),
                  label: const Text('Process All Unprocessed Matches'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(batchUpdateStateProvider.notifier).runWeeklyUpdate();
                  },
                  icon: const Icon(Icons.calendar_view_week),
                  label: const Text('Run Weekly Update'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(batchUpdateStateProvider.notifier).runMonthlyUpdate();
                  },
                  icon: const Icon(Icons.calendar_view_month),
                  label: const Text('Run Monthly Update'),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Results Display
            if (batchUpdateState.isCompleted && batchUpdateState.result != null)
              Card(
                color: batchUpdateState.result!.success ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            batchUpdateState.result!.success ? Icons.check_circle : Icons.error,
                            color: batchUpdateState.result!.success ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            batchUpdateState.result!.success ? 'Update Successful' : 'Update Failed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: batchUpdateState.result!.success ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(batchUpdateState.result!.message),
                      if (batchUpdateState.result!.success) ...[
                        const SizedBox(height: 4),
                        Text('Matches Processed: ${batchUpdateState.result!.matchesProcessed}'),
                        Text('Players Updated: ${batchUpdateState.result!.playersUpdated}'),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(batchUpdateStateProvider.notifier).resetState();
                        },
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              ),

            if (batchUpdateState.hasError)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(batchUpdateState.errorMessage ?? 'Unknown error occurred'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(batchUpdateStateProvider.notifier).resetState();
                        },
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // About Section
            const Divider(),
            const Text(
              'About Glicko-1 Rating System',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This app uses the Glicko-1 rating system to calculate player ratings. '
              'Each player has a rating and a rating deviation (RD) that represents '
              'the uncertainty in their rating. Lower RD means more confidence in the rating.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

