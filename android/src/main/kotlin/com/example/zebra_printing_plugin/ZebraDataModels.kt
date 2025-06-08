package com.example.zebra_printing_plugin

/**
 * Data Transfer Objects for Zebra Printer Plugin
 * These classes handle data communication between Flutter and Android
 */

data class DiscoveredPrinterInfo(
    val macAddress: String,
    val friendlyName: String?
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "macAddress" to macAddress,
            "friendlyName" to friendlyName
        )
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): DiscoveredPrinterInfo {
            return DiscoveredPrinterInfo(
                macAddress = map["macAddress"] as String,
                friendlyName = map["friendlyName"] as String?
            )
        }
    }
}

data class PrinterStatusInfo(
    val isReadyToPrint: Boolean,
    val isPaperOut: Boolean,
    val isHeadOpen: Boolean,
    val isPaused: Boolean,
    val isConnected: Boolean,
    val errorMessage: String? = null
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "isReadyToPrint" to isReadyToPrint,
            "isPaperOut" to isPaperOut,
            "isHeadOpen" to isHeadOpen,
            "isPaused" to isPaused,
            "isConnected" to isConnected,
            "errorMessage" to errorMessage
        )
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): PrinterStatusInfo {
            return PrinterStatusInfo(
                isReadyToPrint = map["isReadyToPrint"] as Boolean,
                isPaperOut = map["isPaperOut"] as Boolean,
                isHeadOpen = map["isHeadOpen"] as Boolean,
                isPaused = map["isPaused"] as Boolean,
                isConnected = map["isConnected"] as Boolean,
                errorMessage = map["errorMessage"] as String?
            )
        }
    }
}

data class PrintJobInfo(
    val zplData: String,
    val copies: Int = 1
) {
    companion object {
        fun fromMap(map: Map<String, Any?>): PrintJobInfo {
            return PrintJobInfo(
                zplData = map["zplData"] as String,
                copies = (map["copies"] as Number?)?.toInt() ?: 1
            )
        }
    }
}
