import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:monik/helper/safe_url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Monik',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('About Monik')),
      children: [
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(FluentIcons.devices2, size: 50, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Information',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 20),
              _buildInfoRow('Name', _packageInfo.appName),
              _buildInfoRow('Version', _packageInfo.version),
              _buildInfoRow('Build Number', _packageInfo.buildNumber),
              _buildInfoRow('Platform', Platform.operatingSystem),
              _buildInfoRow('OS Version', Platform.operatingSystemVersion),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              const Text(
                'Monik is a powerful desktop application that provides advanced control for your monitors and input devices, offering a software alternative to traditional KVM switches.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 20),
              Text(
                'Features',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              _buildFeatureItem('Monitor brightness and input source control'),
              _buildFeatureItem('System tray integration for quick access'),
              _buildFeatureItem('Multi-monitor support'),
              _buildFeatureItem('System information display'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credits',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              const Text(
                '© 2025 bhavukar\n\n'
                'This application is built with Flutter and Fluent UI.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton(
                child: const Text('Project Repository'),
                onPressed: () {
                  // Open the project repository URL
                  const url = 'https://github.com/bhavukar/monik.git';
                  // Use url_launcher or any other method to open the URL
                  openURLExternal(url);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0, right: 8.0),
            child: Icon(FluentIcons.circle_fill, size: 8),
          ),
          Expanded(child: Text(feature)),
        ],
      ),
    );
  }
}
