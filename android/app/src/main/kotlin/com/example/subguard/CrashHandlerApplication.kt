package com.example.subguard

import android.app.Application
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter

class CrashHandlerApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val sw = StringWriter()
                throwable.printStackTrace(PrintWriter(sw))
                val logFile = File(filesDir, "crash_log.txt")
                logFile.writeText(
                    "Crash at ${System.currentTimeMillis()}\nThread: ${thread.name}\n\n$sw"
                )
                val externalDir = getExternalFilesDir(null)
                if (externalDir != null) {
                    File(externalDir, "crash_log.txt").writeText(
                        "Crash at ${System.currentTimeMillis()}\nThread: ${thread.name}\n\n$sw"
                    )
                }
            } catch (e: Exception) {
                // Never let the crash handler itself throw
            }
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
}
