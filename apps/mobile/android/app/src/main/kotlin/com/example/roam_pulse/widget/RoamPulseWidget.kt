package com.example.roam_pulse.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

/**
 * The "glance journey" from docs/PRODUCT_DISCOVERY.md §3 — the user
 * checks connectivity/data/expiry from the home screen without opening
 * the app. Reads whatever [WidgetDataRepository] last persisted (written
 * by MainActivity's MethodChannel handler) and renders it through the
 * pure [mapToWidgetUiState]; this class itself stays a thin composition
 * shell with no formatting logic of its own.
 */
class RoamPulseWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val uiState = mapToWidgetUiState(WidgetDataRepository(context).read())
        provideContent { WidgetContent(uiState) }
    }
}

@Composable
private fun WidgetContent(state: WidgetUiState) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color.White)
            .padding(12.dp),
    ) {
        Text(
            text = state.connectionLabel,
            style = TextStyle(
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = ColorProvider(toneColor(state.connectionTone)),
            ),
        )
        state.carrierLine?.let {
            Text(text = it, style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.DarkGray)))
        }
        Spacer(modifier = GlanceModifier.height(8.dp))
        state.destinationLine?.let {
            Text(text = it, style = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Medium))
        }
        state.dataRemainingLabel?.let {
            Text(
                text = "$it remaining",
                style = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.Bold),
            )
        }
        state.expiryLabel?.let {
            Text(text = it, style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.DarkGray)))
        }
        state.lastUpdatedLabel?.let {
            Text(
                text = "Updated $it",
                style = TextStyle(fontSize = 10.sp, color = ColorProvider(Color.Gray)),
            )
        }
    }
}

private fun toneColor(tone: ConnectionTone): Color = when (tone) {
    ConnectionTone.POSITIVE -> Color(0xFF2E7D32)
    ConnectionTone.WARNING -> Color(0xFFF9A825)
    ConnectionTone.NEGATIVE -> Color(0xFFC62828)
    ConnectionTone.NEUTRAL -> Color(0xFF616161)
}
