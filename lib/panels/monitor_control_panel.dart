import 'package:fluent_ui/fluent_ui.dart';
import 'package:monik/services/monitor_configurator.dart';
import 'package:screen_brightness/screen_brightness.dart';

class MonitorDetails {
  final String name;
  final String resolution;
  final String refreshRate;
  final String currentInput;
  final List<String> availableInputs;
  final double currentBrightness; // 0.0 to 1.0
  final int id; // Unique identifier for the monitor

  MonitorDetails({
    required this.name,
    required this.resolution,
    required this.refreshRate,
    required this.currentInput,
    required this.availableInputs,
    required this.currentBrightness,
    required this.id,
  });
}

class MonitorControlPage extends StatefulWidget {
  const MonitorControlPage({super.key});

  @override
  State<MonitorControlPage> createState() => _MonitorControlPageState();
}

class _MonitorControlPageState extends State<MonitorControlPage> {
  List<MonitorDetails> _monitors = [];
  int _selectedMonitorIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllMonitors();
  }

  Future<void> _fetchAllMonitors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call native code to get all monitors
      final monitorList = await MonitorService.instance.getAllMonitors();

      if (monitorList.isEmpty) {
        // Fallback with placeholder data if no monitors found
        final currentSysBrightness = await ScreenBrightness.instance.system;
        _monitors = [
          MonitorDetails(
            id: 0,
            name: 'Primary Display (Generic PnP Monitor)',
            resolution: '1920x1080',
            refreshRate: '60 Hz',
            currentInput: 'HDMI 1',
            availableInputs: ['HDMI 1', 'HDMI 2', 'DisplayPort 1'],
            currentBrightness: currentSysBrightness,
          ),
        ];
      } else {
        _monitors = monitorList;
      }

      _selectedMonitorIndex = 0;
    } catch (e) {
      _errorMessage = 'Failed to fetch monitor details: ${e.toString()}';
      _monitors = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCurrentMonitor() async {
    if (_monitors.isEmpty) {
      await _fetchAllMonitors();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call native code to refresh just the current monitor
      final updatedMonitor = await MonitorService.instance.getMonitorDetails(
        _monitors[_selectedMonitorIndex].id,
      );

      setState(() {
        _monitors[_selectedMonitorIndex] = updatedMonitor;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to refresh monitor: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _setBrightness(double brightness) async {
    if (_monitors.isEmpty) return;

    try {
      await MonitorService.instance.setBrightness(
        _monitors[_selectedMonitorIndex].id,
        brightness,
      );

      // Update the UI state after successful native call
      setState(() {
        _monitors[_selectedMonitorIndex] = MonitorDetails(
          id: _monitors[_selectedMonitorIndex].id,
          name: _monitors[_selectedMonitorIndex].name,
          resolution: _monitors[_selectedMonitorIndex].resolution,
          refreshRate: _monitors[_selectedMonitorIndex].refreshRate,
          currentInput: _monitors[_selectedMonitorIndex].currentInput,
          availableInputs: _monitors[_selectedMonitorIndex].availableInputs,
          currentBrightness: brightness,
        );
      });

      _showInfoBar('Brightness updated to ${(brightness * 100).toInt()}%');
    } catch (e) {
      _showInfoBar(
        'Failed to set brightness: ${e.toString()}',
        severity: InfoBarSeverity.error,
      );
    }
  }

  Future<void> _setInputSource(String inputSource) async {
    if (_monitors.isEmpty) return;

    try {
      // Map your UI input source names to the numeric codes expected by the monitor
      final Map<String, int> inputSourceCodes = {
        'HDMI 1': 0x11,
        'HDMI 2': 0x12,
        'DisplayPort 1': 0x0F,
        // Add other input sources and their codes as needed
      };

      final sourceCode = inputSourceCodes[inputSource];
      if (sourceCode == null) {
        _showInfoBar(
          'Unknown input source code',
          severity: InfoBarSeverity.error,
        );
        return;
      }

      // Call your native implementation
      await MonitorService.instance.setInputSource(
        _monitors[_selectedMonitorIndex].id,
        sourceCode,
      );

      // Update UI state if successful
      setState(() {
        _monitors[_selectedMonitorIndex] = MonitorDetails(
          id: _monitors[_selectedMonitorIndex].id,
          name: _monitors[_selectedMonitorIndex].name,
          resolution: _monitors[_selectedMonitorIndex].resolution,
          refreshRate: _monitors[_selectedMonitorIndex].refreshRate,
          currentInput: inputSource,
          availableInputs: _monitors[_selectedMonitorIndex].availableInputs,
          currentBrightness: _monitors[_selectedMonitorIndex].currentBrightness,
        );
      });

      _showInfoBar('Input source changed to $inputSource');
    } catch (e) {
      _showInfoBar(
        'Failed to set input source: ${e.toString()}',
        severity: InfoBarSeverity.error,
      );
    }
  }

  void _showInfoBar(
    String message, {
    InfoBarSeverity severity = InfoBarSeverity.info,
  }) {
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: Text(message),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
          severity: severity,
        );
      },
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: FluentTheme.of(
                context,
              ).typography.bodyStrong?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _fetchAllMonitors,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_monitors.isEmpty) {
      return const Center(child: Text('No monitors detected.'));
    }

    final monitor = _monitors[_selectedMonitorIndex];

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Row(
          children: [
            Expanded(
              child: ComboBox<int>(
                placeholder: const Text('Select Monitor'),
                value: _selectedMonitorIndex,
                items: List.generate(
                  _monitors.length,
                  (index) => ComboBoxItem<int>(
                    value: index,
                    child: Text(_monitors[index].name),
                  ),
                ),
                onChanged: (index) {
                  if (index != null) {
                    setState(() {
                      _selectedMonitorIndex = index;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _refreshCurrentMonitor,
            ),
          ],
        ),
      ),
      children: [
        const SizedBox(height: 20),
        // Current monitor info banner
        InfoBar(
          title: Text(
            '${monitor.resolution} @ ${monitor.refreshRate} | Input: ${monitor.currentInput}',
          ),
          isLong: true,
          severity: InfoBarSeverity.info,
        ),
        const SizedBox(height: 20),
        Card(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitor Details',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              InfoLabel(label: 'Name:', child: Text(monitor.name)),
              const SizedBox(height: 8),
              InfoLabel(label: 'Resolution:', child: Text(monitor.resolution)),
              const SizedBox(height: 8),
              InfoLabel(
                label: 'Refresh Rate:',
                child: Text(monitor.refreshRate),
              ),
              const SizedBox(height: 8),
              InfoLabel(
                label: 'Current Input:',
                child: Text(monitor.currentInput),
              ),
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
                'Brightness Control',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      label: '${(monitor.currentBrightness * 100).toInt()}%',
                      value: monitor.currentBrightness,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        // Update UI optimistically
                        setState(() {
                          _monitors[_selectedMonitorIndex] = MonitorDetails(
                            id: monitor.id,
                            name: monitor.name,
                            resolution: monitor.resolution,
                            refreshRate: monitor.refreshRate,
                            currentInput: monitor.currentInput,
                            availableInputs: monitor.availableInputs,
                            currentBrightness: value,
                          );
                        });
                      },
                      onChangeEnd: (value) {
                        // Actual call to native code after user finishes sliding
                        _setBrightness(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('${(monitor.currentBrightness * 100).toInt()}%'),
                ],
              ),
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
                'Input Source',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              ComboBox<String>(
                placeholder: const Text('Select Input Source'),
                isExpanded: true,
                items:
                    monitor.availableInputs.map((input) {
                      return ComboBoxItem(value: input, child: Text(input));
                    }).toList(),
                value:
                    monitor.availableInputs.contains(monitor.currentInput)
                        ? monitor.currentInput
                        : null,
                onChanged: (value) {
                  if (value != null) {
                    _setInputSource(value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Note: Make sure to select the correct monitor from the dropdown above.',
          style: FluentTheme.of(context).typography.caption,
        ),
      ],
    );
  }
}
