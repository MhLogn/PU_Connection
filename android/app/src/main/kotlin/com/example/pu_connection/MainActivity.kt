package com.example.pu_connection

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize Google Play Services security provider asynchronously in background.
        // This prevents ProviderInstaller.installIfNeeded from synchronously blocking the Android UI Looper
        // when Firebase / Firestore connects.
        thread(start = true, isDaemon = true, name = "SecurityProviderWarmup") {
            try {
                val installerClass = Class.forName("com.google.android.gms.security.ProviderInstaller")
                val method = installerClass.getMethod("installIfNeeded", android.content.Context::class.java)
                method.invoke(null, applicationContext)
            } catch (_: Throwable) {
                // Ignore if Play Services is absent or already up-to-date
            }
        }
    }
}
