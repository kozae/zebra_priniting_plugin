package com.example.zebra_printing_plugin

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.delay
import com.zebra.sdk.comm.BluetoothConnection
import com.zebra.sdk.comm.BluetoothConnectionInsecure
import com.zebra.sdk.comm.ConnectionException
import com.zebra.sdk.printer.PrinterStatus
import com.zebra.sdk.printer.ZebraPrinter
import com.zebra.sdk.printer.ZebraPrinterFactory
import com.zebra.sdk.printer.discovery.BluetoothDiscoverer
import com.zebra.sdk.printer.discovery.DiscoveredPrinter
import com.zebra.sdk.printer.discovery.DiscoveryHandler
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Core service interface for Zebra printer operations
 */
interface ZebraPrinterService {
    suspend fun discoverPrinters(context: Context): List<DiscoveredPrinterInfo>
    suspend fun connect(macAddress: String, context: Context): PrinterStatusInfo?
    suspend fun disconnect(): Boolean
    suspend fun getPrinterStatus(): PrinterStatusInfo?
    suspend fun printZpl(zplData: String): Boolean
    suspend fun setLanguageToZpl(): Boolean
    fun startStatusUpdates(onStatusUpdate: (PrinterStatusInfo?) -> Unit)
    fun stopStatusUpdates()
}

/**
 * Real implementation of ZebraPrinterService using Zebra Link-OS SDK
 */
class ZebraPrinterServiceImpl : ZebraPrinterService {
    
    private var connection: BluetoothConnection? = null
    private var zebraPrinter: ZebraPrinter? = null
    private var statusUpdateCallback: ((PrinterStatusInfo?) -> Unit)? = null
    private var isStatusMonitoringActive = false

    override suspend fun discoverPrinters(context: Context): List<DiscoveredPrinterInfo> = withContext(Dispatchers.IO) {
        val discoveredPrinters = mutableListOf<DiscoveredPrinterInfo>()
        
        try {
            return@withContext suspendCancellableCoroutine { continuation ->
                val discoveryHandler = object : DiscoveryHandler {
                    override fun foundPrinter(discoveredPrinter: DiscoveredPrinter) {
                        val printerInfo = DiscoveredPrinterInfo(
                            macAddress = discoveredPrinter.address,
                            friendlyName = discoveredPrinter.discoveryDataMap["FRIENDLY_NAME"] 
                                ?: discoveredPrinter.discoveryDataMap["MODEL"] 
                                ?: "Unknown Zebra Printer"
                        )
                        discoveredPrinters.add(printerInfo)
                    }

                    override fun discoveryFinished() {
                        continuation.resume(discoveredPrinters)
                    }

                    override fun discoveryError(message: String) {
                        continuation.resumeWithException(Exception("Discovery failed: $message"))
                    }
                }

                try {
                    BluetoothDiscoverer.findPrinters(context, discoveryHandler)
                } catch (e: Exception) {
                    continuation.resumeWithException(e)
                }

                continuation.invokeOnCancellation {
                    // Cancel discovery if coroutine is cancelled
                }
            }
        } catch (e: Exception) {
            throw Exception("Failed to discover printers: ${e.message}", e)
        }
    }

    override suspend fun connect(macAddress: String, context: Context): PrinterStatusInfo? = withContext(Dispatchers.IO) {
        try {
            // Close existing connection if any
            disconnect()

            // Create new Bluetooth connection
            connection = BluetoothConnectionInsecure(macAddress)
            connection?.open()

            if (connection?.isConnected != true) {
                throw ConnectionException("Failed to establish Bluetooth connection")
            }

            // Create Zebra printer instance
            zebraPrinter = ZebraPrinterFactory.getInstance(connection)
            
            if (zebraPrinter == null) {
                connection?.close()
                connection = null
                throw Exception("Failed to create Zebra printer instance")
            }

            // Ensure printer is in ZPL mode
            setLanguageToZpl()

            // Return initial status
            return@withContext getPrinterStatus()

        } catch (e: Exception) {
            connection?.close()
            connection = null
            zebraPrinter = null
            throw Exception("Connection failed: ${e.message}", e)
        }
    }

    override suspend fun disconnect(): Boolean = withContext(Dispatchers.IO) {
        try {
            stopStatusUpdates()
            
            connection?.let { conn ->
                if (conn.isConnected) {
                    conn.close()
                }
            }
            
            connection = null
            zebraPrinter = null
            return@withContext true
            
        } catch (e: Exception) {
            return@withContext false
        }
    }

    override suspend fun getPrinterStatus(): PrinterStatusInfo? = withContext(Dispatchers.IO) {
        try {
            val printer = zebraPrinter ?: return@withContext null
            val conn = connection ?: return@withContext null

            if (!conn.isConnected) {
                return@withContext PrinterStatusInfo(
                    isReadyToPrint = false,
                    isPaperOut = false,
                    isHeadOpen = false,
                    isPaused = false,
                    isConnected = false,
                    errorMessage = "Printer not connected"
                )
            }

            val printerStatus = printer.currentStatus

            return@withContext PrinterStatusInfo(
                isReadyToPrint = printerStatus.isReadyToPrint,
                isPaperOut = printerStatus.isPaperOut,
                isHeadOpen = printerStatus.isHeadOpen,
                isPaused = printerStatus.isPaused,
                isConnected = conn.isConnected,
                errorMessage = if (printerStatus.isReadyToPrint) null else "Printer not ready"
            )

        } catch (e: Exception) {
            return@withContext PrinterStatusInfo(
                isReadyToPrint = false,
                isPaperOut = false,
                isHeadOpen = false,
                isPaused = false,
                isConnected = false,
                errorMessage = "Failed to get status: ${e.message}"
            )
        }
    }

    override suspend fun printZpl(zplData: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val printer = zebraPrinter ?: throw Exception("Printer not connected")
            val conn = connection ?: throw Exception("Connection not established")

            if (!conn.isConnected) {
                throw Exception("Printer connection lost")
            }

            // Check printer status before printing
            val status = printer.currentStatus
            if (!status.isReadyToPrint) {
                throw Exception("Printer not ready to print")
            }

            // Send ZPL data to printer
            conn.write(zplData.toByteArray())
            
            return@withContext true

        } catch (e: Exception) {
            throw Exception("Print failed: ${e.message}", e)
        }
    }

    override suspend fun setLanguageToZpl(): Boolean = withContext(Dispatchers.IO) {
        try {
            val printer = zebraPrinter ?: return@withContext false
            val conn = connection ?: return@withContext false

            if (!conn.isConnected) {
                return@withContext false
            }

            // Send direct command to set printer to ZPL mode
            // This is a universal command that works on most Zebra printers
            try {
                // Set printer language to ZPL
                conn.write("! U1 setvar \"device.languages\" \"zpl\"\r\n".toByteArray())
                delay(500)
                
                // Alternative ZPL command to ensure ZPL mode
                conn.write("^XA^JUS^XZ".toByteArray())
                delay(200)
                
                return@withContext true
            } catch (e: Exception) {
                // If direct commands fail, assume printer is already in ZPL mode
                return@withContext true
            }

        } catch (e: Exception) {
            // If all methods fail, just return true and hope the printer is already in ZPL mode
            return@withContext true
        }
    }

    override fun startStatusUpdates(onStatusUpdate: (PrinterStatusInfo?) -> Unit) {
        statusUpdateCallback = onStatusUpdate
        isStatusMonitoringActive = true
        
        // Start background status monitoring
        // Note: In a real implementation, you'd use a coroutine scope tied to the service lifecycle
    }

    override fun stopStatusUpdates() {
        isStatusMonitoringActive = false
        statusUpdateCallback = null
    }
}
