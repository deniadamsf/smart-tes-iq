package com.cellanomadigital.smart_tes_iq

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.cellanomadigital.smart_tes_iq/app_info"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Aktifkan Edge-to-Edge sesuai rekomendasi Android 15 (SDK 35)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getAppVersion") {
                    try {
                        val pkgInfo = packageManager.getPackageInfo(packageName, 0)
                        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pkgInfo.longVersionCode.toInt()
                        } else {
                            @Suppress("DEPRECATION")
                            pkgInfo.versionCode
                        }
                        result.success(
                            mapOf(
                                "versionName" to (pkgInfo.versionName ?: "2.3.5"),
                                "versionCode" to versionCode
                            )
                        )
                    } catch (e: Exception) {
                        result.error("ERR_VERSION", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
