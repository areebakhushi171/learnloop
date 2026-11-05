import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common/app_app_bar.dart';
import '../widgets/common/app_button.dart';

class CertificateScreen extends StatelessWidget {
  final String courseTitle;
  final String studentName;

  const CertificateScreen({
    super.key,
    required this.courseTitle,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Course Certificate'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber),
              const SizedBox(height: AppTheme.spaceLg),
              Text('Certificate of Completion', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.spaceMd),
              Text('This is proudly presented to', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceSm),
              Text(studentName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppTheme.spaceSm),
              Text('for successfully completing the course', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceSm),
              Text(courseTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: AppTheme.spaceXl),
              AppButton(
                text: 'Download / Share PDF',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Certificate downloaded successfully!'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
