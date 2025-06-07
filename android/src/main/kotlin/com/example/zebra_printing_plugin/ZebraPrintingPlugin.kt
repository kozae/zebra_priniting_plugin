package com.example.zebra_printing_plugin

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.cancel

/** ZebraPrintingPlugin */
class ZebraPrintingPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    
    companion object {
        private const val METHOD_CHANNEL_NAME = "com.example.zebra_printing_plugin/methods"
        private const val EVENT_CHANNEL_NAME = "com.example.zebra_printing_plugin/status"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    
    private val printerService: ZebraPrinterService = ZebraPrinterServiceImpl()
    private val pluginScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            
            "discoverPrinters" -> {
                pluginScope.launch {
                    try {
                        val printers = printerService.discoverPrinters(context)
                        val printerMaps = printers.map { it.toMap() }
                        result.success(printerMaps)
                    } catch (e: Exception) {
                        result.error("DISCOVERY_ERROR", e.message, null)
                    }
                }
            }
            
            "connect" -> {
                val macAddress = call.argument<String>("macAddress")
                if (macAddress == null) {
                    result.error("INVALID_ARGUMENT", "macAddress is required", null)
                    return
                }
                
                pluginScope.launch {
                    try {
                        val status = printerService.connect(macAddress, context)
                        if (status != null) {
                            result.success(status.toMap())
                        } else {
                            result.error("CONNECTION_FAILED", "Failed to connect to printer", null)
                        }
                    } catch (e: Exception) {
                        result.error("CONNECTION_ERROR", e.message, null)
                    }
                }
            }
            
            "disconnect" -> {
                pluginScope.launch {
                    try {
                        val success = printerService.disconnect()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("DISCONNECT_ERROR", e.message, null)
                    }
                }
            }
            
            "getPrinterStatus" -> {
                pluginScope.launch {
                    try {
                        val status = printerService.getPrinterStatus()
                        if (status != null) {
                            result.success(status.toMap())
                        } else {
                            result.error("STATUS_ERROR", "Failed to get printer status", null)
                        }
                    } catch (e: Exception) {
                        result.error("STATUS_ERROR", e.message, null)
                    }
                }
            }
            
            "printZpl" -> {
                val zplData = call.argument<String>("zplData")
                if (zplData == null) {
                    result.error("INVALID_ARGUMENT", "zplData is required", null)
                    return
                }
                
                pluginScope.launch {
                    try {
                        val success = printerService.printZpl(zplData)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("PRINT_ERROR", e.message, null)
                    }
                }
            }
            
            "setLanguageToZpl" -> {
                pluginScope.launch {
                    try {
                        val success = printerService.setLanguageToZpl()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("LANGUAGE_ERROR", e.message, null)
                    }
                }
            }
            
            "startStatusUpdates" -> {
                try {
                    printerService.startStatusUpdates { status ->
                        eventSink?.success(status?.toMap())
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("STATUS_MONITOR_ERROR", e.message, null)
                }
            }
            
            "stopStatusUpdates" -> {
                try {
                    printerService.stopStatusUpdates()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("STATUS_MONITOR_ERROR", e.message, null)
                }
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        // Clean up resources
        pluginScope.launch {
            printerService.disconnect()
        }
        pluginScope.cancel()
    }

    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        printerService.stopStatusUpdates()
    }
}
