import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info2/system_info2.dart';

class SystemSnapshot {
  const SystemSnapshot({
    required this.os,
    required this.version,
    required this.build,
    required this.hostname,
    required this.architecture,
    required this.processor,
    required this.totalRam,
    required this.freeRam,
    required this.totalDisk,
    required this.freeDisk,
    required this.cpuUsage,
  });

  final String os;
  final String version;
  final String build;
  final String hostname;
  final String architecture;
  final String processor;
  final int? totalRam;
  final int? freeRam;
  final int? totalDisk;
  final int? freeDisk;
  final double? cpuUsage;

  double? get ramUsage => _percentage(totalRam, freeRam);
  double? get diskUsage => _percentage(totalDisk, freeDisk);
}

double? _percentage(int? total, int? free) {
  if (total == null || free == null || total <= 0) return null;
  return ((total - free) / total).clamp(0, 1).toDouble();
}

int? _readMetric(int Function() read) {
  try {
    final value = read();
    return value > 0 ? value : null;
  } catch (_) {
    return null;
  }
}

Future<SystemSnapshot> readSystemSnapshot({
  bool includePerformanceMetrics = true,
}) async {
  final info = await DeviceInfoPlugin().deviceInfo;
  var os = Platform.operatingSystem;
  var version = Platform.operatingSystemVersion;
  var build = 'Unavailable';
  var hostname = 'Unavailable';
  var architecture = Platform.version;

  if (info is AndroidDeviceInfo) {
    os = 'Android';
    version = info.version.release;
    build = 'SDK ${info.version.sdkInt} · ${info.display}';
    hostname = _localHostname();
    architecture = info.supportedAbis.join(', ');
  } else if (info is WindowsDeviceInfo) {
    os = info.productName;
    version = info.displayVersion;
    build = info.buildNumber.toString();
    hostname = info.computerName;
    architecture =
        Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'Unavailable';
  } else if (info is LinuxDeviceInfo) {
    os = info.prettyName;
    version = info.version ?? Platform.operatingSystemVersion;
    build = info.buildId ?? 'Unavailable';
    hostname = _localHostname();
    architecture = _tryArchitecture();
  } else if (info is MacOsDeviceInfo) {
    os = 'macOS';
    version = info.osRelease;
    build = '${info.majorVersion}.${info.minorVersion}.${info.patchVersion}';
    hostname = info.computerName;
    architecture = info.arch;
  }

  var memoryTotal = includePerformanceMetrics
      ? _readMetric(SysInfo.getTotalPhysicalMemory)
      : null;
  var memoryFree = includePerformanceMetrics
      ? _readMetric(SysInfo.getAvailablePhysicalMemory)
      : null;
  var diskTotal =
      includePerformanceMetrics ? _readMetric(SysInfo.getTotalStorage) : null;
  var diskFree =
      includePerformanceMetrics ? _readMetric(SysInfo.getFreeStorage) : null;
  if (includePerformanceMetrics &&
      Platform.isWindows &&
      (memoryTotal == null ||
          memoryFree == null ||
          diskTotal == null ||
          diskFree == null)) {
    final fallback = await _readWindowsCapacity();
    memoryTotal ??= fallback.$1;
    memoryFree ??= fallback.$2;
    diskTotal ??= fallback.$3;
    diskFree ??= fallback.$4;
  }
  var processor = _readProcessor();
  if (includePerformanceMetrics &&
      Platform.isWindows &&
      processor == 'Unavailable') {
    processor = await _readWindowsProcessor();
  }
  return SystemSnapshot(
    os: os,
    version: version,
    build: build,
    hostname: hostname,
    architecture: architecture,
    processor: processor,
    totalRam: memoryTotal,
    freeRam: memoryFree,
    totalDisk: diskTotal,
    freeDisk: diskFree,
    cpuUsage:
        includePerformanceMetrics ? await _readCpuUsage() : null,
  );
}

String _localHostname() {
  try {
    final value = Platform.localHostname.trim();
    return value.isEmpty ? 'Unavailable' : value;
  } catch (_) {
    return 'Unavailable';
  }
}

String _tryArchitecture() {
  try {
    return SysInfo.rawKernelArchitecture;
  } catch (_) {
    return 'Unavailable';
  }
}

Future<String> _readWindowsProcessor() async {
  try {
    final result = await Process.run(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)',
      ],
    ).timeout(const Duration(seconds: 5));
    final name = result.stdout.toString().trim();
    return result.exitCode == 0 && name.isNotEmpty ? name : 'Unavailable';
  } catch (_) {
    return 'Unavailable';
  }
}

Future<(int?, int?, int?, int?)> _readWindowsCapacity() async {
  try {
    final result = await Process.run(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'''$os=Get-CimInstance Win32_OperatingSystem; $disk=Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:' | Select-Object -First 1; [PSCustomObject]@{TotalRam=[int64]$os.TotalVisibleMemorySize*1KB; FreeRam=[int64]$os.FreePhysicalMemory*1KB; TotalDisk=[int64]$disk.Size; FreeDisk=[int64]$disk.FreeSpace} | ConvertTo-Json -Compress''',
      ],
    ).timeout(const Duration(seconds: 5));
    if (result.exitCode != 0) return (null, null, null, null);
    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    int? number(String key) => (json[key] as num?)?.toInt();
    return (
      number('TotalRam'),
      number('FreeRam'),
      number('TotalDisk'),
      number('FreeDisk'),
    );
  } catch (_) {
    return (null, null, null, null);
  }
}

String _readProcessor() {
  try {
    final cores = SysInfo.cores;
    final name = cores.map((core) => core.name).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );
    return name.isEmpty ? 'Unavailable' : name;
  } catch (_) {
    return 'Unavailable';
  }
}

int? _lastTotalTicks;
int? _lastIdleTicks;

Future<double?> _readCpuUsage() async {
  if (Platform.isWindows) {
    try {
      var result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          r"(Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue",
        ],
      ).timeout(const Duration(seconds: 3));
      var value = result.exitCode == 0
          ? double.tryParse(result.stdout.toString().trim())
          : null;
      if (value == null) {
        result = await Process.run(
          'powershell.exe',
          [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            r'(Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average',
          ],
        ).timeout(const Duration(seconds: 3));
        if (result.exitCode != 0) return null;
        value = double.tryParse(result.stdout.toString().trim());
      }
      return value?.clamp(0, 100).toDouble();
    } catch (_) {
      return null;
    }
  }
  if (Platform.isAndroid || Platform.isLinux) {
    try {
      final firstLine = const LineSplitter()
          .convert(await File('/proc/stat').readAsString())
          .firstWhere((line) => line.startsWith('cpu '));
      final ticks = firstLine
          .trim()
          .split(RegExp(r'\s+'))
          .skip(1)
          .map(int.parse)
          .toList();
      final total = ticks.reduce((a, b) => a + b);
      final idle = ticks[3] + (ticks.length > 4 ? ticks[4] : 0);
      final previousTotal = _lastTotalTicks;
      final previousIdle = _lastIdleTicks;
      _lastTotalTicks = total;
      _lastIdleTicks = idle;
      if (previousTotal == null || previousIdle == null) return null;
      final elapsed = total - previousTotal;
      if (elapsed <= 0) return null;
      return (1 - (idle - previousIdle) / elapsed).clamp(0, 1).toDouble() * 100;
    } catch (_) {
      return null;
    }
  }
  return null;
}

String formatBytes(int? bytes) {
  if (bytes == null) return 'Unavailable';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var amount = bytes.toDouble();
  var unit = 0;
  while (amount >= 1024 && unit < units.length - 1) {
    amount /= 1024;
    unit++;
  }
  return '${amount.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}
