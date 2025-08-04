import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';
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
        child: SingleChildScrollView(
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      playersAsyncValue.when(
                        loading: () => const Text('Loading players...'),
                        error: (error, stackTrace) =>
                            Text('Error loading players: $error'),
                        data: (players) =>
                            Text('Total Players: ${players.length}'),
                      ),
                      matchesAsyncValue.when(
                        loading: () => const Text('Loading matches...'),
                        error: (error, stackTrace) =>
                            Text('Error loading matches: $error'),
                        data: (matches) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Matches: ${matches.length}'),
                            Text(
                                'Unprocessed Matches: ${matches.where((m) => !m.isRatingProcessed).length}'),
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
                'The matches are processed in 7-day chunks. '
                'You can also export/import players and matches as CSV files.',
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
                      ref
                          .read(batchUpdateStateProvider.notifier)
                          .processAllUnprocessedMatches();
                    },
                    icon: const Icon(Icons.update),
                    label: const Text('Process All Unprocessed Matches'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final file = await ref
                          .read(batchUpdateStateProvider.notifier)
                          .exportPlayersToCsv();
                      final bytes = await file.readAsBytes();
                      final savedPath = await FileSaver.instance.saveFile(
                        name: 'players',
                        bytes: bytes,
                        fileExtension: 'csv',
                        mimeType: MimeType.text,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Players exported to $savedPath')),
                        );
                      }
                      final params = ShareParams(
                          subject: 'Players CSV Export',
                          files: [XFile(file.path)],
                          text: 'Players CSV Export');
                      await SharePlus.instance.share(params);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export Players as CSV'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final file = await ref
                          .read(batchUpdateStateProvider.notifier)
                          .exportMatchesToCsv();
                      final bytes = await file.readAsBytes();
                      final savedPath = await FileSaver.instance.saveFile(
                        name: 'matches',
                        bytes: bytes,
                        fileExtension: 'csv',
                        mimeType: MimeType.text,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Matches exported to $savedPath')),
                        );
                      }
                      final params = ShareParams(
                          subject: 'Matches CSV Export',
                          files: [XFile(file.path)],
                          text: 'Matches CSV Export');
                      await SharePlus.instance.share(params);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export Matches as CSV'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['csv'],
                      );
                      if (result != null) {
                        final file = File(result.files.single.path!);
                        await ref
                            .read(batchUpdateStateProvider.notifier)
                            .importPlayersFromCsv(file);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Players imported from CSV')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Import Players from CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['csv'],
                      );
                      if (result != null) {
                        final file = File(result.files.single.path!);
                        await ref
                            .read(batchUpdateStateProvider.notifier)
                            .importMatchesFromCsv(file);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Matches imported from CSV')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Import Matches from CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(batchUpdateStateProvider.notifier)
                          .resetAllMatchesAndPlayers();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset All Ratings & Match States'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Results Display
              if (batchUpdateState.isCompleted &&
                  batchUpdateState.result != null)
                Card(
                  color: batchUpdateState.result!.success
                      ? Colors.green[50]
                      : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              batchUpdateState.result!.success
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: batchUpdateState.result!.success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              batchUpdateState.result!.success
                                  ? 'Update Successful'
                                  : 'Update Failed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: batchUpdateState.result!.success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(batchUpdateState.result!.message),
                        if (batchUpdateState.result!.success) ...[
                          const SizedBox(height: 4),
                          Text(
                              'Matches Processed: ${batchUpdateState.result!.matchesProcessed}'),
                          Text(
                              'Players Updated: ${batchUpdateState.result!.playersUpdated}'),
                        ],
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(batchUpdateStateProvider.notifier)
                                .resetState();
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
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(batchUpdateState.errorMessage ??
                            'Unknown error occurred'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(batchUpdateStateProvider.notifier)
                                .resetState();
                          },
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

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
      ),
    );
  }
}
