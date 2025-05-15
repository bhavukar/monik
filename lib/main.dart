import 'package:fluent_ui/fluent_ui.dart';
import 'package:monik/panels/about.dart';
import 'package:monik/panels/monitor_control_panel.dart';
import 'package:monik/panels/system_info.dart';
import 'package:monik/services/tray_service.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: "Monik",
  );

  // Set window options
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize tray
  await TrayService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();

    // Setup tray listeners
    TrayService.instance.setupListeners(_showApp, _exitApp);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    TrayService.instance.removeListeners();
    super.dispose();
  }

  void _showApp() async {
    await windowManager.show();
    await windowManager.focus();
  }

  void _exitApp() async {
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    // Hide window to system tray instead of closing
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Monik',
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),

      theme: FluentThemeData.light(),
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
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        displayMode: PaneDisplayMode.compact,
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
          PaneItem(
            icon: const Icon(FluentIcons.info),
            title: const Text('About'),
            body: const Center(child: AboutPage()),
          ),
        ],
      ),
    );
  }
}
