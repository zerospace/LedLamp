typedef enum Mode: uint8_t {
    Color,
    Rainbow
} Mode;

struct State {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    Mode mode;
};

void state_serialize(State &state, char *buffer, size_t &size) {
    size_t offset = 0;

    buffer[offset++] = state.red;
    buffer[offset++] = state.green;
    buffer[offset++] = state.blue;
    buffer[offset++] = static_cast<uint8_t>(state.mode);

    size = offset;
}

void deserialize_state(const char *buffer, State &state) {
    size_t offset = 0;

    state.red = static_cast<uint8_t>(buffer[offset++]);
    state.green = static_cast<uint8_t>(buffer[offset++]);
    state.blue = static_cast<uint8_t>(buffer[offset++]);
    state.mode = static_cast<Mode>(buffer[offset++]);
}