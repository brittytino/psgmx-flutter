import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/leetcode_provider.dart';
import '../../models/leetcode_stats.dart';
import '../../services/connectivity_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/offline_error_view.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<LeetCodeStats>>(
        future: context.read<LeetCodeProvider>().fetchLeaderboard(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            final isOffline = !ConnectivityService().hasConnection;
            if (isOffline) {
              return const OfflineErrorView(
                title: 'Unable to Load Leaderboard',
                message: 'Connect to the internet to view rankings',
              );
            }
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No data available yet."));
          }

          final list = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = list[index];
              final rank = index + 1;
              
              Color? rankColor;
              if (rank == 1) {
                rankColor = const Color(0xFFFFD700);
              } else if (rank == 2) {
                rankColor = const Color(0xFFC0C0C0);
              } else if (rank == 3) {
                rankColor = const Color(0xFFCD7F32);
              }

              return ListTile(
                leading: Container(
                  width: 36, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rankColor?.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: rankColor != null ? Border.all(color: rankColor) : null,
                  ),
                  child: Text(
                    "$rank", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: rankColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Solved: ${user.totalSolved} • Weekly: ${user.weeklyScore}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${user.easySolved}", style: const TextStyle(color: Colors.green, fontSize: 10)),
                    Text("${user.mediumSolved}", style: const TextStyle(color: Colors.orange, fontSize: 10)),
                    Text("${user.hardSolved}", style: const TextStyle(color: Colors.red, fontSize: 10)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
