import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Privacy Policy Page
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.sunsetGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: January 2025',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnDark.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                _buildSection(
                  '1. Information We Collect',
                  '''
We collect information you provide directly to us:

• Account information: email address, nickname, and profile picture
• Location data: to detect your current city for personalized recommendations
• Checklists and check-ins: cities you've explored, photos you've uploaded
• Subscription information: if you purchase a premium subscription

We do not collect your precise location continuously. We only request location access when you choose to use our location detection feature.
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '2. How We Use Your Information',
                  '''
We use the information we collect to:

• Provide and improve our services
• Generate personalized city exploration checklists
• Store your checklists and check-in photos
• Process your subscription and payments
• Communicate with you about service updates
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '3. Data Storage and Security',
                  '''
• Your data is stored securely on Supabase cloud infrastructure
• Photos are stored in encrypted cloud storage
• We implement industry-standard security measures
• Your data is isolated by user account - each user's data is completely separate
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '4. Data Sharing',
                  '''
We do not sell your personal data to third parties.

We may share data with:
• Service providers who help us operate our app (Supabase, AI services)
• Legal authorities when required by law

Third-party services we use:
• Supabase: Database and authentication
• DeepSeek AI: Checklist generation
• Apple: In-app purchases (if you subscribe)
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '5. Your Rights',
                  '''
You have the right to:

• Access your personal data
• Update or delete your account
• Export your data
• Opt-out of location tracking
• Cancel your subscription at any time
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '6. Location Permissions',
                  '''
We request location access to:

• Automatically detect your current city
• Provide relevant city recommendations
• Improve your user experience

You can:
• Grant or deny location permission at any time
• Manually select a city if you prefer not to share location
• Change your permission in device settings
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '7. Children\'s Privacy',
                  '''
Our service is not intended for children under 13. We do not knowingly collect information from children under 13.
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '8. Changes to This Policy',
                  '''
We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.

Updated: January 2025
''',
                ),

                const SizedBox(height: 24),

                _buildSection(
                  '9. Contact Us',
                  '''
If you have questions about this privacy policy, please contact us:

Email: privacy@roamquest.app
Website: www.roamquest.app
''',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.9),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
