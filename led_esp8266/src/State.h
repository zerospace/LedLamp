#include <FastLED.h>

typedef enum Mode: uint8_t {
    Color,
    Rainbow
} Mode;

struct State {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t brightness;
    Mode mode;
    ColorTemperature temperature;
};

void state_serialize(State &state, char *buffer, size_t &size) {
    size_t offset = 0;

    buffer[offset++] = state.red;
    buffer[offset++] = state.green;
    buffer[offset++] = state.blue;
    buffer[offset++] = state.brightness;
    buffer[offset++] = static_cast<uint8_t>(state.mode);
    buffer[offset++] = (state.temperature >> 16) & 0xFF;
    buffer[offset++] = (state.temperature >> 8) & 0xFF;
    buffer[offset++] = state.temperature & 0xFF;

    size = offset;
}

void deserialize_state(const char *buffer, State &state) {
    size_t offset = 0;

    state.red = static_cast<uint8_t>(buffer[offset++]);
    state.green = static_cast<uint8_t>(buffer[offset++]);
    state.blue = static_cast<uint8_t>(buffer[offset++]);
    state.brightness = static_cast<uint8_t>(buffer[offset++]);
    state.mode = static_cast<Mode>(buffer[offset++]);

    state.temperature = static_cast<ColorTemperature>(
        (static_cast<uint32_t>(buffer[offset++]) << 16) |
        (static_cast<uint32_t>(buffer[offset++]) << 8) |
        static_cast<uint32_t>(buffer[offset++])
    );
}