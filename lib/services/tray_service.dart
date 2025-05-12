import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

class TrayService {
  static final TrayService _instance = TrayService._internal();
  static TrayService get instance => _instance;

  TrayService._internal();

  Future<void> initialize() async {
    // Set tray icon
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/icons/tray_icon.ico'
          : 'assets/icons/tray_icon.png',
    );

    // Set tooltip
    await trayManager.setToolTip('Monik - Monitor Control');

    // Create menu
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show Monitor Control'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );

    // Set context menu
    await trayManager.setContextMenu(menu);
  }

  void setupListeners(Function showApp, Function exitApp) {
    trayManager.addListener(
      TrayManagerListener(showApp: showApp, exitApp: exitApp),
    );
  }

  void removeListeners() {
    trayManager.removeListener(TrayManagerListener());
  }
}

class TrayManagerListener with TrayListener {
  final Function? showApp;
  final Function? exitApp;

  TrayManagerListener({this.showApp, this.exitApp});

  @override
  void onTrayIconMouseDown() {
    // Show app when tray icon is clicked
    showApp?.call();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        showApp?.call();
        break;
      case 'exit_app':
        exitApp?.call();
        break;
    }
  }
}
