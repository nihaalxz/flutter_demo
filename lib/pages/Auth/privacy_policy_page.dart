import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ adapts to dark mode
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ??
            theme.scaffoldBackgroundColor, // ✅ theme-based
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: SafeArea( // ✅ Added SafeArea
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated: August 17, 2025',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor, // ✅ lighter in light mode, softer in dark mode
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to P2P Rental. We are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              _PolicySection(
                title: '1. Information We Collect',
                content:
                    'We may collect information about you in a variety of ways. The information we may collect via the Application includes:\n\n'
                    '• Personal Data: Personally identifiable information, such as your name, email address, and telephone number, that you voluntarily give to us when you register with the Application.\n'
                    '• Derivative Data: Information our servers automatically collect when you access the Application, such as your IP address, your browser type, your operating system, your access times, and the pages you have viewed directly before and after accessing the Application.',
              ),
              _PolicySection(
                title: '2. How We Use Your Information',
                content:
                    'Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via the Application to:\n\n'
                    '• Create and manage your account.\n'
                    '• Email you regarding your account or order.\n'
                    '• Enable user-to-user communications.\n'
                    '• Process payments and refunds.',
              ),
              _PolicySection(
                title: '3. Disclosure of Your Information',
                content:
                    'We may share information we have collected about you in certain situations. Your information may be disclosed as follows:\n\n'
                    '• By Law or to Protect Rights: If we believe the release of information about you is necessary to respond to legal process, to investigate or remedy potential violations of our policies, or to protect the rights, property, and safety of others, we may share your information as permitted or required by any applicable law, rule, or regulation.',
              ),
              _PolicySection(
                title: '4. Security of Your Information',
                content:
                    'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.',
              ),
              _PolicySection(
                title: '5. Contact Us',
                content:
                    'If you have questions or comments about this Privacy Policy, please contact us at:\n\n'
                    'P2P Rental Support\n'
                    'support@p2prental.com',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
