import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:database_benchmarks/core/utils/build_mode.dart';
import 'package:database_benchmarks/features/benchmark/domain/entities/device_metadata.dart';

class DeviceMetadataService {
  const DeviceMetadataService();

  Future<DeviceMetadata> load() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String device = 'unknown';
    String osVersion = 'unknown';
    bool? hardwareAes;

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      device = '${info.manufacturer} ${info.model}';
      osVersion = 'Android ${info.version.release}';
      hardwareAes = await _detectAndroidHardwareAes();
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      device = '${info.name} ${info.model}';
      osVersion = 'iOS ${info.systemVersion}';
      hardwareAes = _detectIosHardwareAes(info.isPhysicalDevice, info.utsname.machine);
    }

    return DeviceMetadata(
      device: device,
      os: Platform.operatingSystem,
      osVersion: osVersion,
      appVersion: packageInfo.version,
      buildMode: detectBuildMode(),
      hardwareAes: hardwareAes,
    );
  }

  Future<bool?> _detectAndroidHardwareAes() async {
    try {
      final cpuInfo = await File('/proc/cpuinfo').readAsString();
      final lower = cpuInfo.toLowerCase();
      return RegExp(r'\baes\b').hasMatch(lower);
    } catch (_) {
      return null;
    }
  }

  bool? _detectIosHardwareAes(bool isPhysicalDevice, String machine) {
    if (isPhysicalDevice) return true;
    final lowerMachine = machine.toLowerCase();
    if (lowerMachine.contains('x86_64') || lowerMachine.contains('i386')) {
      return false;
    }
    if (lowerMachine.contains('arm64')) {
      return true;
    }
    return null;
  }
}
