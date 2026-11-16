package com.group22.dailo

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Dials USSD codes for the Dart side over the method channel "dailo/ussd".
 * The one method, "dial", takes a `code` string and answers with one of:
 * launched, permissionDenied, noSim, unsupported.
 */
class MainActivity : FlutterActivity() {
    private val callPermissionRequest = 42

    // The Dart call that is waiting for the user to answer the permission dialog.
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCode: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dailo/ussd")
            .setMethodCallHandler { call, result ->
                if (call.method == "dial") {
                    dial(call.argument<String>("code") ?: "", result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun dial(code: String, result: MethodChannel.Result) {
        val granted = checkSelfPermission(Manifest.permission.CALL_PHONE) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success(startCall(code))
        } else {
            // Ask the user, then finish the call in onRequestPermissionsResult.
            pendingResult = result
            pendingCode = code
            requestPermissions(arrayOf(Manifest.permission.CALL_PHONE), callPermissionRequest)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != callPermissionRequest) return
        val result = pendingResult ?: return
        val code = pendingCode ?: ""
        pendingResult = null
        pendingCode = null
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        result.success(if (granted) startCall(code) else "permissionDenied")
    }

    /** Starts the call and returns the outcome name for Dart. */
    private fun startCall(code: String): String {
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
            return "unsupported"
        }
        val telephony = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        if (telephony.simState != TelephonyManager.SIM_STATE_READY) return "noSim"

        // A "#" would end the tel: address early, so it is sent as %23.
        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:" + Uri.encode(code)))
        if (intent.resolveActivity(packageManager) == null) return "unsupported"
        startActivity(intent)
        return "launched"
    }
}
