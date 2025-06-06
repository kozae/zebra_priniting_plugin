import 'package:flutter_test/flutter_test.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_platform_interface.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockZebraPrintingPluginPlatform
    with MockPlatformInterfaceMixin
    implements ZebraPrintingPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ZebraPrintingPluginPlatform initialPlatform = ZebraPrintingPluginPlatform.instance;

  test('$MethodChannelZebraPrintingPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZebraPrintingPlugin>());
  });

  test('getPlatformVersion', () async {
    ZebraPrintingPlugin zebraPrintingPlugin = ZebraPrintingPlugin();
    MockZebraPrintingPluginPlatform fakePlatform = MockZebraPrintingPluginPlatform();
    ZebraPrintingPluginPlatform.instance = fakePlatform;

    expect(await zebraPrintingPlugin.getPlatformVersion(), '42');
  });
}
