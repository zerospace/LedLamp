package com.example.ledlamp

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.example.ledlamp.ui.theme.LedLampTheme
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Observer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {
    private lateinit var networkService: NetworkService

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        networkService = NetworkService(this)
        networkService.search()

        enableEdgeToEdge()
        setContent {
            LedLampTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    val color = remember { mutableStateOf(Color.Red) }
                    val state = remember { mutableStateOf(LampState()) }
                    var isModePickerExpanded = remember { mutableStateOf(false) }

                    val observer = Observer<LampState> { newState ->
                        state.value = newState
                        color.value = Color(newState.red / 255f, newState.green / 255f, newState.blue /255f)
                        Log.d("NetworkService", "Observe state: $newState")
                    }
                    networkService.state.observe(this, observer)

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
                            CircularColorPicker(color) { newColor, isEnded ->
                                state.value = state.value.copy(red = newColor.red * 255, green = newColor.green * 255, blue = newColor.blue * 255)
                                if (isEnded) {
                                    send(state.value)
                                }
                            }
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("R", fontSize = 17.sp)
                            Slider(
                                value = state.value.red,
                                valueRange = 0f..255f,
                                onValueChange = { value ->
                                    state.value = state.value.copy(red = value)
                                    color.value = Color(state.value.red / 255f, state.value.green / 255f, state.value.blue /255f)
                                },
                                onValueChangeFinished = {
                                    send(state.value)
                                }
                            )
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("G", fontSize = 17.sp)
                            Slider(
                                value = state.value.green,
                                valueRange = 0f..255f,
                                onValueChange = { value ->
                                    state.value = state.value.copy(green = value)
                                    color.value = Color(state.value.red / 255f, state.value.green / 255f, state.value.blue /255f)
                                },
                                onValueChangeFinished = {
                                    send(state.value)
                                }
                            )
                        }

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("B", fontSize = 17.sp)
                            Slider(
                                value = state.value.blue,
                                valueRange = 0f..255f,
                                onValueChange = { value ->
                                    state.value = state.value.copy(blue = value)
                                    color.value = Color(state.value.red / 255f, state.value.green / 255f, state.value.blue /255f)
                                },
                                onValueChangeFinished = {
                                    send(state.value)
                                }
                            )
                        }

                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 16.dp)
                                .clickable { isModePickerExpanded.value = true }
                                .border(
                                    width = 1.dp,
                                    color = Color.Gray,
                                    shape = RoundedCornerShape(5.dp)
                                )
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("Mode", modifier = Modifier.padding(8.dp))
                                Spacer(Modifier.weight(1f))
                                Text(state.value.mode.title, modifier = Modifier.padding(8.dp))
                            }
                            DropdownMenu(
                                expanded = isModePickerExpanded.value,
                                onDismissRequest = { isModePickerExpanded.value = false },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                LampState.Mode.entries.forEach { option ->
                                    DropdownMenuItem(
                                        text = { Text(option.title) },
                                        onClick = {
                                            state.value = state.value.copy(mode = option)
                                            send(state.value)
                                            isModePickerExpanded.value = false
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        networkService.stop()
    }

    private fun send(state: LampState) {
        CoroutineScope(Dispatchers.Main).launch {
            withContext(Dispatchers.IO) {
                networkService.command(command = LedProtocol.Command.SET, data = state.bytes)
            }
        }
    }
}