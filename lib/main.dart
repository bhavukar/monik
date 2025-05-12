import 'package:fluent_ui/fluent_ui.dart';
import 'package:monik/panels/monitor_control_panel.dart';
import 'package:monik/panels/system_info.dart';
import 'package:monik/services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize tray
  await TrayService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Windows Monitor Control',
      themeMode: ThemeMode.system,
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      theme: FluentThemeData(
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      home: const MainNavigationView(),
    );
  }
}

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text('Windows Monitor Control'),
        automaticallyImplyLeading: false,
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        displayMode: PaneDisplayMode.top,
        items: [
          PaneItem(
            icon: Icon(FluentIcons.personalize),
            title: const Text('Monitor Control'),
            body: const MonitorControlPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.pc1),
            title: const Text('System Info'),
            body: const SystemInfoPage(),
          ),
        ],
      ),
    );
  }
}
