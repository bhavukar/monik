import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:monik/panels/monitor_control_panel.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:win32/win32.dart';

// Load required DLLs
final _dxva2 = DynamicLibrary.open('dxva2.dll');

// Define GetVCPFeatureAndVCPFeatureReply
final getVCPFeatureAndVCPFeatureReply = _dxva2.lookupFunction<
  Int32 Function(
    IntPtr hMonitor,
    Uint32 vcpCode,
    Pointer<Uint32> pvct,
    Pointer<Uint32> pdwCurrentValue,
    Pointer<Uint32> pdwMaximumValue,
  ),
  int Function(
    int hMonitor,
    int vcpCode,
    Pointer<Uint32> pvct,
    Pointer<Uint32> pdwCurrentValue,
    Pointer<Uint32> pdwMaximumValue,
  )
>('GetVCPFeatureAndVCPFeatureReply');

// Bind SetVCPFeature manually
final setVCPFeature = _dxva2.lookupFunction<
  Int32 Function(IntPtr hMonitor, Uint32 vcpCode, Uint32 newValue),
  int Function(int hMonitor, int vcpCode, int newValue)
>('SetVCPFeature');

class MonitorService {
  // Singleton boilerplate
  MonitorService._privateConstructor();
  static final MonitorService _instance = MonitorService._privateConstructor();
  static MonitorService get instance => _instance;

  // Store source code globally since we can't pass custom data directly
  static int _currentSourceCode = 0;

  // Get all connected monitors with their details
  Future<List<MonitorDetails>> getAllMonitors() async {
    final List<MonitorDetails> monitors = [];

    // Call EnumDisplayMonitors and collect monitor details
    final result = await _enumerateMonitors((int monitorHandle) async {
      // For each monitor, get its details and add to the list
      final details = await getMonitorDetails(monitorHandle);
      monitors.add(details);
      return true; // Continue enumeration
    });

    if (!result) {
      throw Exception('Failed to enumerate monitors');
    }

    return monitors;
  }

  // Get details for a specific monitor by ID
  Future<MonitorDetails> getMonitorDetails(int monitorId) async {
    // Implementation to get details for a specific monitor handle
    // This would query monitor properties like resolution, refresh rate, etc.

    // Placeholder implementation - replace with actual Win32 API calls
    final currentSysBrightness = await ScreenBrightness().system;

    // Get monitor details from native code
    final monitorName = await _getMonitorName(monitorId);
    final resolution = await _getMonitorResolution(monitorId);
    final refreshRate = await _getMonitorRefreshRate(monitorId);
    final currentInput = await _getMonitorCurrentInput(monitorId);
    final availableInputs = await _getMonitorAvailableInputs(monitorId);

    return MonitorDetails(
      id: monitorId,
      name: monitorName,
      resolution: resolution,
      refreshRate: refreshRate,
      currentInput: currentInput,
      availableInputs: availableInputs,
      currentBrightness: currentSysBrightness,
    );
  }

  Future<void> setInputSource(int monitorId, int sourceCode) async {
    try {
      final numPhysicalMonitors = calloc<Uint32>();
      final success = GetNumberOfPhysicalMonitorsFromHMONITOR(
        monitorId,
        numPhysicalMonitors,
      );

      if (success == 0 || numPhysicalMonitors.value == 0) {
        calloc.free(numPhysicalMonitors);
        print("❌ Failed to get physical monitors for ID: $monitorId");
        return;
      }

      final physicalMonitors = calloc<PHYSICAL_MONITOR>(
        numPhysicalMonitors.value,
      );
      final gotMonitors = GetPhysicalMonitorsFromHMONITOR(
        monitorId,
        numPhysicalMonitors.value,
        physicalMonitors,
      );

      if (gotMonitors == 0) {
        calloc.free(physicalMonitors);
        calloc.free(numPhysicalMonitors);
        print("❌ Failed to get physical monitor handles for ID: $monitorId");
        return;
      }

      // Set input source only for this specific monitor
      bool suc = false;
      for (int i = 0; i < numPhysicalMonitors.value; i++) {
        final handle = physicalMonitors[i].hPhysicalMonitor;
        final result = setVCPFeature(handle, 0x60, sourceCode);

        if (result == 0) {
          print("❌ Failed to set input source on monitor (handle: $handle)");
        } else {
          print("✅ Input source set on monitor (handle: $handle)");
          suc = true;
        }

        DestroyPhysicalMonitor(handle);
      }

      // Clean up
      calloc.free(physicalMonitors);
      calloc.free(numPhysicalMonitors);

      if (!suc) {
        print("❌ Failed to set input source on any physical monitor");
      }
    } catch (e) {
      print("❌ Error setting input source: $e");
    }
  }

  /// Native-compatible callback that matches the exact WIN32 API signature
  static int _monitorEnumProc(
    int hMonitor,
    int hDC,
    Pointer<NativeType> lpRect,
    int lParam,
  ) {
    return MonitorService.instance._handleMonitor(hMonitor);
  }

  /// Internal method for handling monitor input switch
  int _handleMonitor(int hMonitor) {
    final numPhysicalMonitors = calloc<Uint32>();
    final success =
        GetNumberOfPhysicalMonitorsFromHMONITOR(
          hMonitor,
          numPhysicalMonitors,
        ) !=
        0;

    if (!success) {
      calloc.free(numPhysicalMonitors);
      return 1;
    }

    final physicalMonitors = calloc<PHYSICAL_MONITOR>(
      numPhysicalMonitors.value,
    );
    final gotMonitors =
        GetPhysicalMonitorsFromHMONITOR(
          hMonitor,
          numPhysicalMonitors.value,
          physicalMonitors,
        ) !=
        0;

    if (!gotMonitors) {
      calloc.free(physicalMonitors);
      calloc.free(numPhysicalMonitors);
      return 1;
    }

    for (int i = 0; i < numPhysicalMonitors.value; i++) {
      final handle = physicalMonitors[i].hPhysicalMonitor;

      final result = setVCPFeature(handle, 0x60, _currentSourceCode);
      if (result == 0) {
        print("❌ Failed to set input source on monitor $i");
      } else {
        print("✅ Input source set on monitor $i");
      }

      DestroyPhysicalMonitor(handle);
    }

    calloc.free(physicalMonitors);
    calloc.free(numPhysicalMonitors);

    return 1; // continue enumeration
  }

  // Method to enumerate all monitors and run callback for each
  Future<bool> _enumerateMonitors(
    Future<bool> Function(int monitorHandle) callback,
  ) async {
    // Store callback and results in static variables since EnumDisplayMonitors is synchronous
    _currentCallback = callback;
    _enumResults = [];

    final hdc = GetDC(NULL);

    final result = EnumDisplayMonitors(
      hdc,
      nullptr,
      Pointer.fromFunction<MONITORENUMPROC>(_enumMonitorsProc, 0),
      0,
    );

    ReleaseDC(NULL, hdc);

    // Process results asynchronously
    for (final monitorHandle in _enumResults) {
      final shouldContinue = await callback(monitorHandle);
      if (!shouldContinue) break;
    }

    return result != 0;
  }

  // Static variables to store callback and results
  static Future<bool> Function(int)? _currentCallback;
  static List<int> _enumResults = [];

  // Callback for EnumDisplayMonitors
  static int _enumMonitorsProc(
    int hMonitor,
    int hDC,
    Pointer<NativeType> lpRect,
    int lParam,
  ) {
    // Store monitor handle for later processing
    _enumResults.add(hMonitor);
    return 1; // Continue enumeration
  }

  // Get monitor name using Win32 API
  Future<String> _getMonitorName(int monitorHandle) async {
    // Get the device name associated with this monitor
    final monitorInfo = calloc<MONITORINFOEX>();
    // Initialize cbSize
    monitorInfo.ref.monitorInfo.cbSize = sizeOf<MONITORINFOEX>();

    // Get monitor info
    final success = GetMonitorInfo(monitorHandle, monitorInfo.cast());

    if (success == 0) {
      calloc.free(monitorInfo);
      return 'Unknown Monitor';
    }

    // Extract device name from monitorInfo
    // Use the string directly without casting
    final deviceName = monitorInfo.ref.szDevice;
    calloc.free(monitorInfo);

    // Now get more detailed display device info
    final displayDevice = calloc<DISPLAY_DEVICE>();
    displayDevice.ref.cb = sizeOf<DISPLAY_DEVICE>();

    final deviceSuccess = EnumDisplayDevices(
      TEXT(deviceName),
      0,
      displayDevice,
      0,
    );

    String name;
    if (deviceSuccess != 0) {
      // Get the friendly device name
      // Fix: Correctly convert DISPLAY_DEVICE strings
      name = displayDevice.ref.DeviceString;
    } else {
      // Also attempt to get name from physical monitor
      final numPhysicalMonitors = calloc<Uint32>();
      final physSuccess = GetNumberOfPhysicalMonitorsFromHMONITOR(
        monitorHandle,
        numPhysicalMonitors,
      );

      if (physSuccess != 0 && numPhysicalMonitors.value > 0) {
        final physicalMonitors = calloc<PHYSICAL_MONITOR>(
          numPhysicalMonitors.value,
        );
        final gotMonitors = GetPhysicalMonitorsFromHMONITOR(
          monitorHandle,
          numPhysicalMonitors.value,
          physicalMonitors,
        );

        if (gotMonitors != 0) {
          // Get physical monitor description - use it directly
          name = physicalMonitors[0].szPhysicalMonitorDescription;

          // Clean up physical monitor handles
          for (int i = 0; i < numPhysicalMonitors.value; i++) {
            DestroyPhysicalMonitor(physicalMonitors[i].hPhysicalMonitor);
          }
        } else {
          name = 'Monitor ${monitorHandle & 0xFFFF}';
        }

        calloc.free(physicalMonitors);
      } else {
        name = 'Monitor ${monitorHandle & 0xFFFF}';
      }

      calloc.free(numPhysicalMonitors);
    }

    calloc.free(displayDevice);

    return name.isNotEmpty ? name : 'Monitor ${monitorHandle & 0xFFFF}';
  }

  // Get monitor resolution
  Future<String> _getMonitorResolution(int monitorHandle) async {
    final monitorInfo = calloc<MONITORINFOEX>();
    monitorInfo.ref.monitorInfo.cbSize = sizeOf<MONITORINFOEX>();

    final success = GetMonitorInfo(monitorHandle, monitorInfo.cast());

    if (success == 0) {
      calloc.free(monitorInfo);
      return 'Unknown';
    }

    final rect = monitorInfo.ref.monitorInfo.rcMonitor;
    final width = rect.right - rect.left;
    final height = rect.bottom - rect.top;

    calloc.free(monitorInfo);

    return '${width}x${height}';
  }

  // Get monitor refresh rate
  Future<String> _getMonitorRefreshRate(int monitorHandle) async {
    final monitorInfo = calloc<MONITORINFOEX>();
    monitorInfo.ref.monitorInfo.cbSize = sizeOf<MONITORINFOEX>();

    final success = GetMonitorInfo(monitorHandle, monitorInfo.cast());

    if (success == 0) {
      calloc.free(monitorInfo);
      return 'Unknown';
    }

    // Use string directly without conversion
    final deviceName = monitorInfo.ref.szDevice;
    calloc.free(monitorInfo);

    final devMode = calloc<DEVMODE>();
    devMode.ref.dmSize = sizeOf<DEVMODE>();

    final modeSuccess = EnumDisplaySettings(
      TEXT(deviceName),
      ENUM_CURRENT_SETTINGS,
      devMode,
    );

    if (modeSuccess == 0) {
      calloc.free(devMode);
      return 'Unknown';
    }

    final refreshRate = devMode.ref.dmDisplayFrequency;
    calloc.free(devMode);

    return '$refreshRate Hz';
  }

  // Get current input source
  Future<String> _getMonitorCurrentInput(int monitorHandle) async {
    final numPhysicalMonitors = calloc<Uint32>();
    final success = GetNumberOfPhysicalMonitorsFromHMONITOR(
      monitorHandle,
      numPhysicalMonitors,
    );

    if (success == 0 || numPhysicalMonitors.value == 0) {
      calloc.free(numPhysicalMonitors);
      return 'Unknown';
    }

    final physicalMonitors = calloc<PHYSICAL_MONITOR>(
      numPhysicalMonitors.value,
    );
    final gotMonitors = GetPhysicalMonitorsFromHMONITOR(
      monitorHandle,
      numPhysicalMonitors.value,
      physicalMonitors,
    );

    if (gotMonitors == 0) {
      calloc.free(physicalMonitors);
      calloc.free(numPhysicalMonitors);
      return 'Unknown';
    }

    // Get current VCP feature (0x60 is the input source)
    final currentValue = calloc<Uint32>();
    final maxValue = calloc<Uint32>();

    final vcpSuccess = getVCPFeatureAndVCPFeatureReply(
      physicalMonitors[0].hPhysicalMonitor,
      0x60, // VCP code for input source
      nullptr, // pvct
      currentValue,
      maxValue,
    );

    String inputName = 'Unknown';
    if (vcpSuccess != 0) {
      final code = currentValue.value;
      final inputMap = {
        0x01: 'VGA-1',
        0x02: 'VGA-2',
        0x03: 'DVI-1',
        0x04: 'DVI-2',
        0x0F: 'DisplayPort 1',
        0x10: 'DisplayPort 2',
        0x11: 'HDMI 1',
        0x12: 'HDMI 2',
      };
      inputName = inputMap[code] ?? 'Unknown (0x${code.toRadixString(16)})';
    }

    // Clean up
    for (int i = 0; i < numPhysicalMonitors.value; i++) {
      DestroyPhysicalMonitor(physicalMonitors[i].hPhysicalMonitor);
    }

    calloc.free(physicalMonitors);
    calloc.free(numPhysicalMonitors);
    calloc.free(currentValue);
    calloc.free(maxValue);

    return inputName;
  }

  // Get available input sources
  Future<List<String>> _getMonitorAvailableInputs(int monitorHandle) async {
    // There's no direct Win32 API to get this information
    // Usually, we would query the EDID data or use external libraries
    // For now, we'll return a standard set of inputs

    // You can extend this to read from a configuration file or database
    // based on monitor model detected from EDID
    return ['HDMI 1', 'HDMI 2', 'DisplayPort 1', 'DisplayPort 2', 'VGA'];
  }

  // Method to set the brightness on a specific monitor
  Future<bool> setBrightness(int monitorId, double brightness) async {
    // This uses the platform screen brightness API which applies to the whole system
    // For individual monitor control, you would need to use DDC/CI through SetVCPFeature

    try {
      final numPhysicalMonitors = calloc<Uint32>();
      final success = GetNumberOfPhysicalMonitorsFromHMONITOR(
        monitorId,
        numPhysicalMonitors,
      );

      if (success == 0 || numPhysicalMonitors.value == 0) {
        calloc.free(numPhysicalMonitors);
        // Fallback to system brightness
        await ScreenBrightness().setSystemScreenBrightness(brightness);
        return true;
      }

      final physicalMonitors = calloc<PHYSICAL_MONITOR>(
        numPhysicalMonitors.value,
      );
      final gotMonitors = GetPhysicalMonitorsFromHMONITOR(
        monitorId,
        numPhysicalMonitors.value,
        physicalMonitors,
      );

      if (gotMonitors == 0) {
        calloc.free(physicalMonitors);
        calloc.free(numPhysicalMonitors);
        // Fallback to system brightness
        await ScreenBrightness().setSystemScreenBrightness(brightness);
        return true;
      }

      // Convert 0.0-1.0 to 0-100 range for DDC/CI
      final brightnessValue = (brightness * 100).round();
      bool setSuccess = false;

      for (int i = 0; i < numPhysicalMonitors.value; i++) {
        final result = setVCPFeature(
          physicalMonitors[i].hPhysicalMonitor,
          0x10, // Brightness VCP code
          brightnessValue,
        );

        if (result != 0) {
          setSuccess = true;
        }

        DestroyPhysicalMonitor(physicalMonitors[i].hPhysicalMonitor);
      }

      calloc.free(physicalMonitors);
      calloc.free(numPhysicalMonitors);

      // If DDC/CI failed, fallback to system brightness
      if (!setSuccess) {
        await ScreenBrightness().setSystemScreenBrightness(brightness);
      }

      return true;
    } catch (e) {
      print('Error setting brightness: $e');
      return false;
    }
  }
}
