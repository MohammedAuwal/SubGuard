package com.nassaracoretech.subguard

import android.app.Application
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
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
                val fullTrace = "Thread: ${thread.name}\n\n$sw"

                getSharedPreferences("crash_prefs", MODE_PRIVATE)
                    .edit()
                    .putString("last_crash", fullTrace)
                    .apply()

                val channelId = "crash_channel"
                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channel = NotificationChannel(
                        channelId, "Crash Reports", NotificationManager.IMPORTANCE_HIGH
                    )
                    nm.createNotificationChannel(channel)
                }

                val intent = Intent(this, CrashViewActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    this, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val notification = Notification.Builder(this, channelId)
                    .setSmallIcon(android.R.drawable.stat_notify_error)
                    .setContentTitle("SubGuard crashed - tap to view details")
                    .setContentText(throwable.toString())
                    .setStyle(Notification.BigTextStyle().bigText(fullTrace.take(1000)))
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)
                    .build()

                nm.notify(9911, notification)
            } catch (e: Exception) {
                // Never let the crash handler itself throw
            }
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
}
