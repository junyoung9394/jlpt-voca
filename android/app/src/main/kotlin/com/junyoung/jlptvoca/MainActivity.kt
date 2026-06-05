package com.junyoung.jlptvoca

import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var stylusEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.junyoung.jlptvoca/stylus_input"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                stylusEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                stylusEventSink = null
            }
        })
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        sendStylusEvent(event)
        return super.dispatchTouchEvent(event)
    }

    private fun sendStylusEvent(event: MotionEvent) {
        val type = when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> "down"
            MotionEvent.ACTION_MOVE -> "move"
            MotionEvent.ACTION_UP -> "up"
            MotionEvent.ACTION_CANCEL -> "cancel"
            else -> return
        }
        val pointerIndex = (0 until event.pointerCount).firstOrNull { index ->
            val toolType = event.getToolType(index)
            toolType == MotionEvent.TOOL_TYPE_STYLUS ||
                toolType == MotionEvent.TOOL_TYPE_ERASER
        } ?: return
        val density = resources.displayMetrics.density.toDouble()
        val points = ArrayList<Map<String, Any>>(event.historySize + 1)

        for (historyIndex in 0 until event.historySize) {
            points.add(
                mapOf(
                    "x" to event.getHistoricalX(pointerIndex, historyIndex).toDouble() / density,
                    "y" to event.getHistoricalY(pointerIndex, historyIndex).toDouble() / density,
                    "t" to event.getHistoricalEventTime(historyIndex)
                )
            )
        }
        points.add(
            mapOf(
                "x" to event.getX(pointerIndex).toDouble() / density,
                "y" to event.getY(pointerIndex).toDouble() / density,
                "t" to event.eventTime
            )
        )
        stylusEventSink?.success(
            mapOf(
                "type" to type,
                "device" to event.deviceId,
                "points" to points
            )
        )
    }
}
