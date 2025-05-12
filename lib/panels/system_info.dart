import 'package:fluent_ui/fluent_ui.dart';
import 'package:windows_system_info/windows_system_info.dart';

class SystemInfoPage extends StatefulWidget {
  const SystemInfoPage({super.key});

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  late Future<AllInfo?> _systemInfoFuture;

  @override
  void initState() {
    super.initState();
    _systemInfoFuture = WindowsSystemInfo.initWindowsInfo(
      requiredValues: [WindowsSystemInfoFeat.all],
    ).then((_) => WindowsSystemInfo.windowsSystemInformation);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AllInfo?>(
      future: _systemInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('Failed to load system info'));
        }
        final info = snapshot.data!;
        return ScaffoldPage.scrollable(
          header: const PageHeader(title: Text('System Information')),
          children: [
            // USER & DEVICE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User & Device',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    InfoLabel(
                      label: 'User Name:',
                      child: Text(WindowsSystemInfo.userName),
                    ),
                    InfoLabel(
                      label: 'Device Name:',
                      child: Text(WindowsSystemInfo.deviceName),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // OPERATING SYSTEM
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operating System',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    InfoLabel(
                      label: '64-bit:',
                      child: Text(WindowsSystemInfo.is64bit.toString()),
                    ),
                    InfoLabel(
                      label: '32-bit:',
                      child: Text(WindowsSystemInfo.is32bit.toString()),
                    ),
                    InfoLabel(label: 'Version:', child: Text(info.os.arch)),
                    InfoLabel(
                      label: 'Build Number:',
                      child: Text(info.os.build),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // BIOS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BIOS',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    InfoLabel(label: 'Vendor:', child: Text(info.bios.vendor)),
                    InfoLabel(
                      label: 'Release Date:',
                      child: Text(info.bios.releaseDate),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // BASE BOARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base Board',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    InfoLabel(
                      label: 'Manufacturer:',
                      child: Text(info.baseBoard.manufacturer),
                    ),
                    InfoLabel(
                      label: 'Model:',
                      child: Text(info.baseBoard.model),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // MEMORY MODULES
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memory Modules',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    ...info.memories.map(
                      (mem) => InfoLabel(
                        label: mem.bank,
                        child: Text(
                          '${(mem.size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // DISK LAYOUTS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disk Layouts',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    ...info.disks.map(
                      (d) => InfoLabel(
                        label: d.device,
                        child: Text(
                          '${(d.size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // GRAPHICS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graphics',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    InfoLabel(
                      label: 'Controller:',
                      child: Text(info.graphicsInfo.controllers.join(', ')),
                    ),
                    InfoLabel(
                      label: 'Display:',
                      child: Text(info.graphicsInfo.displays.join(', ')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // NETWORK ADAPTERS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Adapters',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    ...info.network.map(
                      (n) => InfoLabel(label: n.iface, child: Text(n.mac)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
