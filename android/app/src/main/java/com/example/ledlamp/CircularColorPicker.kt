package com.example.ledlamp

import android.annotation.SuppressLint
import android.graphics.Bitmap
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.core.graphics.applyCanvas
import kotlin.math.*

private const val TWO_PI = 2 * Math.PI.toFloat()

@Composable
fun ColorWheel(size: Float) {
    val center = Offset(size / 2, size / 2)
    val radius = center.x

    val colorWheelBitmap = remember(size) {
        val bitmap = Bitmap.createBitmap(size.toInt(), size.toInt(), Bitmap.Config.ARGB_8888)

        bitmap.applyCanvas {
            for (angle in 0 until 360) {
                val paint = android.graphics.Paint().apply {
                    color = android.graphics.Color.HSVToColor(floatArrayOf(angle.toFloat(), 1f, 1f))
                }

                val x = center.x + radius * cos(Math.toRadians(angle.toDouble())).toFloat()
                val y = center.y + radius * sin(Math.toRadians(angle.toDouble())).toFloat()

                drawArc(0f, 0f, size, size, angle.toFloat(), 1.5f, true, paint)
            }
        }

        return@remember bitmap
    }

    val inner = (size * 0.4).toFloat()
    Canvas(modifier = Modifier.fillMaxSize()) {
        val mask = Path().apply {
            addOval(Rect(center = center, radius = radius))
            addOval(Rect(center = center, radius = inner))
            fillType = PathFillType.EvenOdd
        }

        drawContext.canvas.save()
        drawContext.canvas.clipPath(mask, ClipOp.Intersect)
        drawImage(colorWheelBitmap.asImageBitmap())
        drawContext.canvas.restore()
    }
}

@SuppressLint("UnusedBoxWithConstraintsScope")
@Composable
fun CircularColorPicker(color: MutableState<Color>, onColorSelected: (Color) -> Unit) {
    val hsv = FloatArray(3)
    android.graphics.Color.colorToHSV(color.value.toArgb(), hsv)
    var hue = hsv[0] / 360
    var saturation = hsv[1]
    var brightness = hsv[2]

    BoxWithConstraints(modifier = Modifier.aspectRatio(1f)) {
        val size = min(constraints.maxWidth, constraints.maxHeight).toFloat()
        val center = Offset(size/2, size/2)
        val radius = size / 2
        val picker = (size * 0.05).toFloat()
        val saturationBoxSize = size * 0.5f
        val saturationBoxSizeDp = with(LocalDensity.current) { saturationBoxSize.toDp() }

        ColorWheel(size = size)

        Box(modifier = Modifier.fillMaxSize()) {
            Canvas(
                modifier = Modifier.fillMaxSize()
                    .pointerInput(Unit) {
                        detectDragGestures { change, _ ->
                            val dx = change.position.x - center.x
                            val dy = change.position.y - center.y
                            val angle = atan2(dy, dx)
                            hue = if (angle < 0)
                                (angle + TWO_PI) / TWO_PI
                            else
                                angle / TWO_PI
                            color.value = Color.hsv(hue * 360, saturation, brightness)
                            onColorSelected(color.value)
                        }
                    }
            ) {
                val selectorOffset = Offset(
                    x = center.x + (radius - picker) * cos(hue * TWO_PI),
                    y = center.y + (radius - picker) * sin(hue * TWO_PI)
                )

                drawCircle(
                    color = color.value,
                    radius = picker,
                    center = selectorOffset
                )

                drawCircle(
                    color = Color.White,
                    radius = picker,
                    center = selectorOffset,
                    style = Stroke(width = 2.dp.toPx()),
                )
            }
        }

        // MARK: - Saturation/Brightness Box
        Box(
            modifier = Modifier
                .size(saturationBoxSizeDp)
                .align(Alignment.Center)
                .background(
                    brush = Brush.horizontalGradient(
                        colors = listOf(
                            Color.hsv(hue * 360, 0f, 1f),
                            Color.hsv(hue * 360, 1f, 1f)
                        )
                    )
                )
        ) {
            Box(modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Black
                        )
                    )
                )
            )

            val selectorOffset = Offset(
                x = saturationBoxSize * saturation,
                y = saturationBoxSize * (1f - brightness)
            )
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(Unit) {
                        detectDragGestures { change, _ ->
                            val x = max(0f, min(change.position.x, saturationBoxSize))
                            val y = max(0f, min(change.position.y, saturationBoxSize))
                            saturation = x / saturationBoxSize
                            brightness = 1 - (y / saturationBoxSize)
                            color.value = Color.hsv(hue * 360, saturation, brightness)
                            onColorSelected(color.value)
                        }
                    }
            ) {
                drawCircle(
                    color = Color.Gray,
                    radius = 30f,
                    center = selectorOffset,
                    style = Stroke(width = 2.dp.toPx())
                )
            }
        }
    }
}