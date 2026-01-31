import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';

/// Comprehensive Help & Support Screen
/// Provides users with app guidance, FAQs, and support options
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Header
          _buildHeader(context, isDark),
          const SizedBox(height: AppSpacing.xl),

          // Quick Actions
          _buildQuickActions(context, isDark),
          const SizedBox(height: AppSpacing.xl),

          // FAQs Section
          _buildSectionTitle(context, 'Frequently Asked Questions'),
          const SizedBox(height: AppSpacing.md),
          _buildFAQs(context, isDark),
          const SizedBox(height: AppSpacing.xl),

          // App Features Guide
          _buildSectionTitle(context, 'App Features'),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureGuide(context, isDark),
          const SizedBox(height: AppSpacing.xl),

          // Role-Based Access
          _buildSectionTitle(context, 'Role-Based Access'),
          const SizedBox(height: AppSpacing.md),
          _buildRoleAccess(context, isDark),
          const SizedBox(height: AppSpacing.xl),

          // Contact & Support
          _buildSectionTitle(context, 'Contact Support'),
          const SizedBox(height: AppSpacing.md),
          _buildContactSection(context, isDark),
          const SizedBox(height: AppSpacing.xl),

          // App Info
          _buildAppInfo(context, isDark),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return PremiumCard(
      backgroundColor: Theme.of(context).primaryColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re here to help!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find answers, get guidance, or reach out to our support team.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.email_outlined,
            label: 'Email Us',
            color: Colors.blue,
            onTap: () => _launchEmail(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.bug_report_outlined,
            label: 'Report Bug',
            color: Colors.orange,
            onTap: () => _showReportBugDialog(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.lightbulb_outline,
            label: 'Suggest',
            color: Colors.green,
            onTap: () => _showSuggestionDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PremiumCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFAQs(BuildContext context, bool isDark) {
    final faqs = [
      {
        'q': 'How do I update my LeetCode username?',
        'a': 'Go to Profile → Personal Details → LeetCode Username. Tap on it to edit and save your username. Your stats will sync automatically within 24 hours.',
      },
      {
        'q': 'Why can\'t I mark attendance?',
        'a': 'Only Team Leaders can mark attendance for their team members. If you\'re a Team Leader and still can\'t mark attendance, make sure:\n• It\'s a scheduled class day\n• You\'re marking within the allowed time window\n• Your team members are properly assigned to your team',
      },
      {
        'q': 'How is the LeetCode leaderboard calculated?',
        'a': 'The leaderboard tracks two metrics:\n• Weekly Score: Problems solved in the last 7 days\n• Total Score: All-time problems solved\n\nStats are refreshed automatically every 24 hours or manually by Placement Reps.',
      },
      {
        'q': 'How do I receive notifications?',
        'a': 'Ensure notifications are enabled in your phone settings for PSGMX app. You can customize which notifications you receive in Profile → Settings → Notifications.',
      },
      {
        'q': 'What do the different roles mean?',
        'a': 'Student: View personal attendance and LeetCode stats\nTeam Leader: Mark attendance for team members\nCoordinator: View scheduled classes and team analytics\nPlacement Rep: Full access to all features including scheduling and overall analytics',
      },
      {
        'q': 'How accurate is the attendance percentage?',
        'a': 'Attendance is calculated based on scheduled class days only. Non-class days (weekends, holidays) are not counted against your attendance percentage.',
      },
      {
        'q': 'Can I see my attendance history?',
        'a': 'Yes! Go to Attendance → My Attendance tab to view your complete attendance history with dates and status.',
      },
      {
        'q': 'Why is my LeetCode profile picture not showing?',
        'a': 'Profile pictures are fetched from LeetCode. Make sure:\n• Your LeetCode username is correct\n• Your LeetCode profile is public\n• Wait for the next sync cycle (every 24 hours)',
      },
    ];

    return Column(
      children: faqs.map((faq) => _buildFAQItem(context, faq['q']!, faq['a']!, isDark)).toList(),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer, bool isDark) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.help_outline,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGuide(BuildContext context, bool isDark) {
    final features = [
      {
        'icon': Icons.dashboard_rounded,
        'title': 'Home Dashboard',
        'desc': 'View daily inspiration, announcements, personal LeetCode stats, and the class leaderboard.',
      },
      {
        'icon': Icons.code_rounded,
        'title': 'LeetCode Tracking',
        'desc': 'Automatic tracking of your LeetCode progress with weekly and all-time leaderboards.',
      },
      {
        'icon': Icons.assignment_turned_in_rounded,
        'title': 'Attendance System',
        'desc': 'Track attendance for scheduled placement classes with team-wise management.',
      },
      {
        'icon': Icons.task_alt_rounded,
        'title': 'Daily Tasks',
        'desc': 'Stay updated with daily LeetCode problems and core subject topics assigned by coordinators.',
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Reports & Analytics',
        'desc': 'View comprehensive attendance analytics, long absentees, and team-wise breakdowns.',
      },
      {
        'icon': Icons.notifications_rounded,
        'title': 'Notifications',
        'desc': 'Receive push notifications for announcements, reminders, birthdays, and attendance alerts.',
      },
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f['icon'] as IconData, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f['desc'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRoleAccess(BuildContext context, bool isDark) {
    final roles = [
      {
        'role': 'Student',
        'color': Colors.green,
        'access': [
          'View personal attendance history',
          'Track personal LeetCode stats',
          'View class leaderboard',
          'Receive announcements',
        ],
      },
      {
        'role': 'Team Leader',
        'color': Colors.blue,
        'access': [
          'All Student features',
          'Mark attendance for team members',
          'View team attendance summary',
          'Receive attendance reminders',
        ],
      },
      {
        'role': 'Coordinator',
        'color': Colors.orange,
        'access': [
          'All Team Leader features',
          'View scheduled classes',
          'Access team analytics',
          'Post announcements',
        ],
      },
      {
        'role': 'Placement Rep',
        'color': Colors.purple,
        'access': [
          'Full access to all features',
          'Schedule class dates',
          'Refresh LeetCode data manually',
          'View overall attendance analytics',
          'Manage all teams and students',
        ],
      },
    ];

    return Column(
      children: roles.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (r['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: (r['color'] as Color).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      r['role'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: r['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...((r['access'] as List<String>).map((access) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: r['color'] as Color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        access,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ))),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isDark) {
    return PremiumCard(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.email, color: Colors.blue),
            ),
            title: Text(
              'Email Support',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'placement.psgmx@gmail.com',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchEmail(context),
          ),
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat, color: Colors.green),
            ),
            title: Text(
              'WhatsApp Group',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Join class group for quick help',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showWhatsAppInfo(context),
          ),
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: Colors.purple),
            ),
            title: Text(
              'Contact Placement Rep',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'For urgent issues and queries',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPlacementRepContact(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context, bool isDark) {
    return PremiumCard(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PSGMX',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Placement Excellence',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Version 1.2.0',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Made with ❤️ for PSG students',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _showPrivacyPolicy(context),
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
              Text('•', style: TextStyle(color: Colors.grey[400])),
              TextButton(
                onPressed: () => _showTermsOfService(context),
                child: Text(
                  'Terms of Service',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'placement.psgmx@gmail.com',
      queryParameters: {
        'subject': 'PSGMX App Support',
        'body': 'Hello,\n\nI need help with:\n\n[Describe your issue here]\n\nThank you.',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  void _showReportBugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: Colors.orange),
            const SizedBox(width: 10),
            Text('Report a Bug', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found something not working? Help us improve!',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Please include:',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '• What you were trying to do\n'
              '• What happened instead\n'
              '• Steps to reproduce the issue\n'
              '• Screenshots if possible',
              style: GoogleFonts.inter(fontSize: 13, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchEmail(context);
            },
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.green),
            const SizedBox(width: 10),
            Text('Suggest a Feature', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have an idea to make PSGMX better?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'We\'d love to hear your suggestions! Share your ideas with us via email.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchEmail(context);
            },
            child: const Text('Share Idea'),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.chat, color: Colors.green),
            const SizedBox(width: 10),
            Text('WhatsApp Group', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Join the official PSGMX Placement class WhatsApp group for:\n\n'
          '• Quick announcements\n'
          '• Peer support\n'
          '• Instant updates\n\n'
          'Ask your Team Leader for the group invite link.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPlacementRepContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.purple),
            const SizedBox(width: 10),
            Text('Placement Representative', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'For urgent matters that need immediate attention:\n\n'
          '• Attendance corrections\n'
          '• Access issues\n'
          '• Data discrepancies\n\n'
          'Contact your Placement Representative directly through the class WhatsApp group or in person.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'PSGMX Privacy Policy\n\n'
            'Last updated: January 2026\n\n'
            '1. Data Collection\n'
            'We collect only essential information needed for the app\'s functionality:\n'
            '• Email address (PSG college email)\n'
            '• Name and registration number\n'
            '• LeetCode username (optional)\n'
            '• Date of birth (optional, for birthday wishes)\n'
            '• Attendance records\n\n'
            '2. Data Usage\n'
            'Your data is used solely for:\n'
            '• Authentication and authorization\n'
            '• Tracking placement preparation progress\n'
            '• Displaying leaderboards\n'
            '• Sending relevant notifications\n\n'
            '3. Data Security\n'
            'All data is securely stored using Supabase with:\n'
            '• Encrypted connections\n'
            '• Row-level security policies\n'
            '• Role-based access control\n\n'
            '4. Data Sharing\n'
            'We do not sell or share your data with third parties.\n'
            'LeetCode statistics are fetched from public APIs.\n\n'
            '5. Contact\n'
            'For privacy concerns, contact: placement.psgmx@gmail.com',
            style: GoogleFonts.inter(fontSize: 12, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Terms of Service', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'PSGMX Terms of Service\n\n'
            'Last updated: January 2026\n\n'
            '1. Acceptance\n'
            'By using PSGMX, you agree to these terms.\n\n'
            '2. Eligibility\n'
            'This app is exclusively for PSG College of Technology students enrolled in placement preparation programs.\n\n'
            '3. User Responsibilities\n'
            '• Provide accurate information\n'
            '• Maintain account security\n'
            '• Use the app for its intended purpose\n'
            '• Respect other users\n\n'
            '4. Prohibited Activities\n'
            '• Sharing login credentials\n'
            '• Manipulating attendance data\n'
            '• Falsifying LeetCode statistics\n'
            '• Disrupting app services\n\n'
            '5. Attendance Policy\n'
            'Attendance data is official and used for placement tracking.\n'
            'Any disputes should be raised with Coordinators.\n\n'
            '6. Modifications\n'
            'We may update these terms. Continued use implies acceptance.\n\n'
            '7. Contact\n'
            'Questions? Email: placement.psgmx@gmail.com',
            style: GoogleFonts.inter(fontSize: 12, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
