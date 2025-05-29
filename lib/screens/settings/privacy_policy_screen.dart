import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://bambangp.vercel.app/privacy-policy');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Data Collection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'This application does not collect any personal information from its users. We are committed to protecting your privacy and ensuring a secure experience.',
            ),
            const SizedBox(height: 16),
            const Text(
              'What We Don\'t Collect:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Personal information\n'
                '• Location data\n'
                '• Device information\n'
                '• Usage statistics\n'
                '• Cookies or tracking data'),
            const SizedBox(height: 24),
            Text(
              'Data Storage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'All data created and stored within the app remains on your device. We do not transmit or store any information on external servers.',
            ),
            const SizedBox(height: 24),
            Text(
              'Third-Party Services',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'This app does not integrate with any third-party services that would collect user data.',
            ),
            const SizedBox(height: 24),
            Text(
              'Changes to Privacy Policy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'We may update this privacy policy from time to time. Any changes will be reflected in the "Last updated" date at the top of this policy.',
            ),
            const SizedBox(height: 24),
            Text(
              'Contact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions about this privacy policy, please contact us at:',
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _launchURL,
              child: const Text(
                'https://bambangp.vercel.app/privacy-policy',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'By using this application, you agree to the terms of this privacy policy.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
} 