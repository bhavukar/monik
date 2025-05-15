import 'package:url_launcher/url_launcher.dart';

Future<void> openURLExternal(
  String url, [
  LaunchMode mode = LaunchMode.externalApplication,
]) async {
  if (!await launchUrl(Uri.parse(url), mode: mode)) {
    throw Exception('Could not launch $url');
  }
}
