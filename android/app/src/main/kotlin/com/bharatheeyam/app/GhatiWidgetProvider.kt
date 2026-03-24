package com.bharatheeyam.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.widget.RemoteViews
import java.util.Calendar
import kotlin.math.*

class GhatiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
        // Schedule next update
        GhatiWidgetUpdateService.scheduleNextUpdate(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        GhatiWidgetUpdateService.scheduleNextUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        GhatiWidgetUpdateService.cancelUpdates(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.bharatheeyam.CLOCK_UPDATE" ||
            intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                android.content.ComponentName(context, GhatiWidgetProvider::class.java)
            )
            onUpdate(context, mgr, ids)
        }
    }

    companion object {
        private const val WIDGET_SIZE = 400

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.ghati_widget_layout)

            try {
                // Get sunrise from SharedPreferences (saved by Flutter app)
                // Flutter shared_preferences stores doubles as Long bits (Double.doubleToRawLongBits)
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val sunriseHour: Double = try {
                    val longBits = prefs.getLong("flutter.sunrise_hour24", Double.doubleToRawLongBits(6.0))
                    Double.fromBits(longBits)
                } catch (e: ClassCastException) {
                    // Fallback: try reading as float (older versions may have stored it differently)
                    try {
                        prefs.getFloat("flutter.sunrise_hour24", 6.0f).toDouble()
                    } catch (e2: Exception) {
                        6.0
                    }
                }

                // Calculate current ghati
                val cal = Calendar.getInstance()
                val nowHour = cal.get(Calendar.HOUR_OF_DAY) + cal.get(Calendar.MINUTE) / 60.0 + cal.get(Calendar.SECOND) / 3600.0
                val elapsedHours = nowHour - sunriseHour
                val ghati = elapsedHours * (60.0 / 24.0)

                // Draw clock
                val bitmap = drawClock(ghati, WIDGET_SIZE)
                views.setImageViewBitmap(R.id.ghati_clock_image, bitmap)

                // Digital display
                val gh = ghati.toInt() % 60
                val viTotal = (ghati - ghati.toInt()) * 60
                val vi = viTotal.toInt()
                val av = ((viTotal - vi) * 60).toInt()
                views.setTextViewText(R.id.ghati_text, "${gh} ಘ : ${vi.toString().padStart(2, '0')} ವಿ : ${av.toString().padStart(2, '0')} ಅ")

                // Click to open app
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    val pendingIntent = android.app.PendingIntent.getActivity(
                        context, 0, launchIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.ghati_widget_root, pendingIntent)
                }
            } catch (e: Exception) {
                // If anything fails, show a fallback message instead of blank
                views.setTextViewText(R.id.ghati_text, "ಭಾರತೀಯಮ್ - ಅಪ್ ತೆರೆಯಿರಿ")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun drawClock(ghati: Double, size: Int): Bitmap {
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val cx = size / 2f
            val cy = size / 2f
            val R = cx - 8f

            val vighatiTotal = (ghati - ghati.toInt()) * 60
            val vighatiWhole = vighatiTotal.toInt()
            val anuVighati = (vighatiTotal - vighatiWhole) * 60

            val ghatiAngle = ((ghati % 60) * 6.0 - 90).toFloat()
            val vighatiAngle = (vighatiTotal * 6.0 - 90).toFloat()
            val anuAngle = (anuVighati * 6.0 - 90).toFloat()

            // Background
            val bgPaint = Paint().apply {
                shader = RadialGradient(cx, cy, R, intArrayOf(0xFF1A1A2E.toInt(), 0xFF16213E.toInt(), 0xFF0F3460.toInt()), floatArrayOf(0f, 0.5f, 1f), Shader.TileMode.CLAMP)
            }
            canvas.drawCircle(cx, cy, R, bgPaint)

            // Gold ring
            val ringPaint = Paint().apply { color = 0xFFD4AF37.toInt(); style = Paint.Style.STROKE; strokeWidth = 4f; isAntiAlias = true }
            canvas.drawCircle(cx, cy, R, ringPaint)

            // Ghati markers
            for (i in 0 until 60) {
                val a = Math.toRadians((i * 6.0 - 90))
                val isMajor = i % 5 == 0
                val len = if (isMajor) R * 0.08f else R * 0.03f
                val w = if (isMajor) 3f else 1f
                val r1 = R * 0.92f
                val r2 = r1 - len
                val c = if (isMajor) 0xCCFFFFFF.toInt() else 0x33FFFFFF
                val p = Paint().apply { color = c; strokeWidth = w; isAntiAlias = true }
                canvas.drawLine(
                    cx + r2 * cos(a).toFloat(), cy + r2 * sin(a).toFloat(),
                    cx + r1 * cos(a).toFloat(), cy + r1 * sin(a).toFloat(), p
                )

                if (isMajor) {
                    val numR = R * 0.80f
                    val label = if (i == 0) "ಉ" else "$i"
                    val fontSize = if (i == 0) R * 0.06f else R * 0.05f
                    val textColor = if (i == 0) 0xFFFFD700.toInt() else 0xB3FFFFFF.toInt()
                    drawText(canvas, label, cx + numR * cos(a).toFloat(), cy + numR * sin(a).toFloat(), fontSize, textColor, true)
                }
            }

            // Inner ring
            val innerPaint = Paint().apply { color = 0x20D4AF37; style = Paint.Style.STROKE; strokeWidth = 1f; isAntiAlias = true }
            canvas.drawCircle(cx, cy, R * 0.62f, innerPaint)

            // HANDS
            drawHand(canvas, cx, cy, ghatiAngle, R * 0.45f, 6f, 0xFFE53E3E.toInt(), R * 0.08f)    // Ghati - red
            drawHand(canvas, cx, cy, vighatiAngle, R * 0.60f, 4f, 0xFF2B6CB0.toInt(), R * 0.06f)    // Vighati - blue
            drawHand(canvas, cx, cy, anuAngle, R * 0.75f, 2f, 0xFF38A169.toInt(), R * 0.04f)         // AnuVighati - green

            // Center hub
            val hubPaint = Paint().apply {
                shader = RadialGradient(cx, cy, 16f, intArrayOf(0xFFD4AF37.toInt(), 0xFF8B6914.toInt()), null, Shader.TileMode.CLAMP)
                isAntiAlias = true
            }
            canvas.drawCircle(cx, cy, 16f, hubPaint)
            canvas.drawCircle(cx, cy, 16f, Paint().apply { color = 0x4DFFFFFF; style = Paint.Style.STROKE; strokeWidth = 2f; isAntiAlias = true })
            canvas.drawCircle(cx, cy, 6f, Paint().apply { color = 0xFF1A1A2E.toInt(); isAntiAlias = true })

            return bitmap
        }

        private fun drawHand(canvas: Canvas, cx: Float, cy: Float, angleDeg: Float, length: Float, width: Float, color: Int, tailLen: Float) {
            val a = Math.toRadians(angleDeg.toDouble())
            val tipX = cx + length * cos(a).toFloat()
            val tipY = cy + length * sin(a).toFloat()
            val tailX = cx - tailLen * cos(a).toFloat()
            val tailY = cy - tailLen * sin(a).toFloat()

            // Glow
            val glowPaint = Paint().apply { this.color = (color and 0x00FFFFFF) or 0x33000000; strokeWidth = width + 6; strokeCap = Paint.Cap.ROUND; isAntiAlias = true }
            canvas.drawLine(tailX, tailY, tipX, tipY, glowPaint)

            // Shaft
            val shaftPaint = Paint().apply { this.color = color; strokeWidth = width; strokeCap = Paint.Cap.ROUND; isAntiAlias = true }
            canvas.drawLine(tailX, tailY, tipX, tipY, shaftPaint)

            // Arrowhead
            val aW = width * 2.5f
            val aL = width * 4f
            val b1x = tipX - aL * cos(a).toFloat() + aW / 2 * cos(a + PI / 2).toFloat()
            val b1y = tipY - aL * sin(a).toFloat() + aW / 2 * sin(a + PI / 2).toFloat()
            val b2x = tipX - aL * cos(a).toFloat() - aW / 2 * cos(a + PI / 2).toFloat()
            val b2y = tipY - aL * sin(a).toFloat() - aW / 2 * sin(a + PI / 2).toFloat()
            val arrowPath = Path().apply { moveTo(tipX, tipY); lineTo(b1x, b1y); lineTo(b2x, b2y); close() }
            canvas.drawPath(arrowPath, Paint().apply { this.color = color; isAntiAlias = true })
        }

        private fun drawText(canvas: Canvas, text: String, x: Float, y: Float, fontSize: Float, color: Int, bold: Boolean) {
            val paint = Paint().apply {
                this.color = color
                textSize = fontSize
                textAlign = Paint.Align.CENTER
                isAntiAlias = true
                if (bold) typeface = Typeface.DEFAULT_BOLD
            }
            val fm = paint.fontMetrics
            canvas.drawText(text, x, y - (fm.ascent + fm.descent) / 2, paint)
        }
    }
}
