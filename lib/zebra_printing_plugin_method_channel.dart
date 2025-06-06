import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'zebra_printing_plugin_platform_interface.dart';

/// An implementation of [ZebraPrintingPluginPlatform] that uses method channels.
class MethodChannelZebraPrintingPlugin extends ZebraPrintingPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zebra_printing_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
