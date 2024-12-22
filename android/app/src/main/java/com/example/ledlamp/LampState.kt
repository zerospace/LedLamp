package com.example.ledlamp

data class LampState(
    val red: Float = 0f,
    val green: Float = 0f,
    val blue: Float = 0f,
    val mode: Mode = Mode.COLOR
) {
    enum class Mode(val title: String) {
        COLOR("\uD83D\uDCA1 Color"),
        RAINBOW("\uD83C\uDF08 Rainbow")
    }

    companion object {
        fun deserialize(data: ByteArray): LampState {
            var offset = 0
            val red = data[offset]
            offset++
            val green = data[offset]
            offset++
            val blue = data[offset]
            offset++
            val mode = data[offset]
            return LampState(
                red = red.toFloat(),
                green = green.toFloat(),
                blue = blue.toFloat(),
                mode = if (mode.toInt() == 0) Mode.COLOR else Mode.RAINBOW
            )
        }
    }
}
