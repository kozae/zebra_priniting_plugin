
import 'zebra_printing_plugin_platform_interface.dart';

class ZebraPrintingPlugin {
  Future<String?> getPlatformVersion() {
    return ZebraPrintingPluginPlatform.instance.getPlatformVersion();
  }
}
