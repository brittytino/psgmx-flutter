import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../services/quote_service.dart';
import '../../models/task_attendance.dart';
import '../../core/theme/layout_tokens.dart';
import '../../ui/widgets/content_card.dart';
import '../../ui/widgets/loading_state.dart';
import '../../ui/widgets/empty_state.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<SupabaseDbService>(context);
    final quoteService = Provider.of<QuoteService>(context);
    final today = DateTime.now().toIso8601String().split('T')[0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Motivation Card
          FutureBuilder<Map<String, String>>(
            future: quoteService.getDailyQuote(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data!;
              return ContentCard(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Column(
                  children: [
                    Text(
                      '"${data['text']}"',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '- ${data['author']}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "Today's Task", 
            style: Theme.of(context).textTheme.headlineMedium
          ),
          const SizedBox(height: AppSpacing.md),
          
          StreamBuilder<DailyTask?>(
            stream: firestore.getDailyTask(today),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState(message: "Fetching daily task...");
              }
              final task = snapshot.data;
              if (task == null) {
                return const ContentCard(
                  child: EmptyState(
                    title: "No Task Yet",
                    icon: Icons.task_alt,
                    message: "The coordinator hasn't published today's task. Check back later.",
                  ),
                );
              }

              return Column(
                children: [
                   ContentCard(
                    title: "LeetCode Problem", 
                    onTap: () => launchUrl(Uri.parse(task.leetcodeUrl)),
                     trailing: const Icon(Icons.open_in_new),
                    child: Row(
                      children: [
                        Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text("Click to open problem", style: Theme.of(context).textTheme.bodyLarge)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ContentCard(
                    title: "CS Topic: ${task.csTopic}",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: AppSpacing.md),
                            Text("Topic Details", style: Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(task.csTopicDescription, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
