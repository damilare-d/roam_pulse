package com.example.roam_pulse

import androidx.glance.appwidget.updateAll
import com.example.roam_pulse.widget.RoamPulseWidget
import com.example.roam_pulse.widget.WidgetDataRepository
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private const val WIDGET_CHANNEL = "com.roampulse.widget"

/**
 * The native half of NativeWidgetService (Phase 10) — persists whatever
 * Flutter sends via [WIDGET_CHANNEL] and asks the Glance widget to
 * redraw. Everything past "read the call arguments" is delegated to
 * [WidgetDataRepository]/[RoamPulseWidget]; this method-call switch is
 * the only thing that lives here.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val repository = WidgetDataRepository(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateConnectivity" -> {
                        repository.updateConnectivity(
                            state = call.argument<String>("state").orEmpty(),
                            carrierName = call.argument<String>("carrierName").orEmpty(),
                            technology = call.argument<String>("technology").orEmpty(),
                            lastSyncedAt = call.argument<String>("lastSyncedAt").orEmpty(),
                        )
                        refreshWidget()
                        result.success(null)
                    }
                    "updatePlan" -> {
                        repository.updatePlan(
                            destinationCity = call.argument<String>("destinationCity").orEmpty(),
                            countryCode = call.argument<String>("countryCode").orEmpty(),
                            dataRemainingMb = call.argument<Double>("dataRemainingMb") ?: 0.0,
                            dataAllowanceMb = call.argument<Double>("dataAllowanceMb") ?: 0.0,
                            daysRemaining = call.argument<Int>("daysRemaining") ?: 0,
                        )
                        refreshWidget()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun refreshWidget() {
        CoroutineScope(Dispatchers.Main).launch {
            RoamPulseWidget().updateAll(applicationContext)
        }
    }
}
