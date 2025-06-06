import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'zebra_printing_plugin_method_channel.dart';

abstract class ZebraPrintingPluginPlatform extends PlatformInterface {
  /// Constructs a ZebraPrintingPluginPlatform.
  ZebraPrintingPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZebraPrintingPluginPlatform _instance = MethodChannelZebraPrintingPlugin();

  /// The default instance of [ZebraPrintingPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelZebraPrintingPlugin].
  static ZebraPrintingPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZebraPrintingPluginPlatform] when
  /// they register themselves.
  static set instance(ZebraPrintingPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
