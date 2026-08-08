import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _simPdfUrl =
    'https://uspa.org/LinkClick.aspx?fileticket=KMkbZSbEhtQ%3D&portalid=0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'I made this as a personal study aid while going through '
              'my own AFF training, and I\'m sharing it in case it helps '
              'you too.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'This deck is a study aid for practicing recall of AFF '
              'material. It is not a substitute for training from a '
              'certified USPA instructor or for the current official '
              'USPA Skydiver\'s Information Manual (SIM). Always verify '
              'procedures with your instructor and the current SIM.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            InkWell(
              key: const Key('sim-reference-link'),
              onTap: () =>
                  launchUrl(Uri.parse(_simPdfUrl), webOnlyWindowName: '_blank'),
              child: const Text(
                'Content reference: 2026 USPA SIM.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
