package com.nassaracoretech.subguard

import android.app.Activity
import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView

class CrashViewActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val trace = getSharedPreferences("crash_prefs", MODE_PRIVATE)
            .getString("last_crash", "No crash recorded.")

        val textView = TextView(this).apply {
            text = trace
            textSize = 12f
            setPadding(24, 24, 24, 24)
            setTextIsSelectable(true)
        }

        val scrollView = ScrollView(this).apply {
            addView(textView)
        }

        setContentView(scrollView)
    }
}
