package com.example.ledlamp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.example.ledlamp.ui.theme.LedLampTheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            LedLampTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    val color = remember { mutableStateOf(Color.Red) }
                    var red = remember { mutableFloatStateOf(0f) }
                    var green = remember { mutableFloatStateOf(0f) }
                    var blue = remember { mutableFloatStateOf(0f) }

                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularColorPicker(color) { newColor ->
                                red.floatValue = newColor.red * 255
                                green.floatValue = newColor.green * 255
                                blue.floatValue = newColor.blue * 255
                            }
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("R", fontSize = 17.sp)
                            Slider(
                                value = red.floatValue,
                                valueRange = 0f..255f,
                                onValueChange = { value ->
                                    red.floatValue = value
                                    color.value = Color(red.floatValue / 255f, green.floatValue / 255f, blue.floatValue /255f)
                                },
                                onValueChangeFinished =  {}
                            )
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("G", fontSize = 17.sp)
                            Slider(
                                value = green.floatValue,
                                valueRange = 0f..255f,
                                onValueChange = { value ->
                                    green.floatValue = value
                                    color.value = Color(red.floatValue / 255f, green.floatValue / 255f, blue.floatValue /255f)
                                },
                                onValueChangeFinished =  {}
                            )
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("B", fontSize = 17.sp)
                            Slider(
                                value = blue.floatValue,
                                valueRange = 0f..255f,
                                onValueChange = { value ->
                                    blue.floatValue = value
                                    color.value = Color(red.floatValue / 255f, green.floatValue / 255f, blue.floatValue /255f)
                                },
                                onValueChangeFinished =  {}
                            )
                        }
                    }
                }
            }
        }
    }
}