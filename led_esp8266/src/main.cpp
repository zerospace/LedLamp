#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <ESPAsyncTCP.h>
#include "WiFiConfig.h"
#include "packet/Packet.h"
#include <memory.h>
#include "State.h"

const int num_leds = 60;

State state;
CRGB leds[num_leds];
AsyncServer server(12345);
Parser parser;

uint8_t rainbow_counter;
uint8_t last_red_state = 0;
uint8_t last_green_state = 0;
uint8_t last_blue_state = 0;
uint8_t last_bright_state = 0;
bool need_update_led = true;

// Forward declarations
void send(State &state, PacketType type, Function command, AsyncClient *client);

void setup() {
  Serial.begin(9600);
  delay(10);

  state.red = 255;
  state.green = 244;
  state.blue = 229;
  state.brightness = 128;
  state.mode = Color;
  state.temperature = Tungsten100W;

  FastLED.addLeds<WS2812, D7, GRB>(leds, num_leds).setCorrection(TypicalLEDStrip);

  WiFi.begin(SSID, PASSWORD);
  MDNS.begin("esp8266");
  MDNS.addService("lamp", "tcp", 12345);

  server.onClient([](void *arg, AsyncClient *client) {
    client->onData([](void *arg, AsyncClient *client, void *data, size_t length) {
      char* buffer = static_cast<char*>(data);
      Packet packet;
      if (parser.parse(buffer, length, &packet) == 0) {
        switch (packet.type) {
          case Command:
            switch (packet.command) {
              case SetState:
                deserialize_state(packet.data, state);
                need_update_led = true;
                break;

              case GetState:
                send(state, Response, GetState, client);
                break;
            }
            break;

          case Response:
            break;
        }
      }
    }, nullptr);

    client->onDisconnect([](void *arg, AsyncClient *client) {
      delete client;
    }, nullptr);
  }, nullptr);
  server.begin();
}

void loop() {
  MDNS.update();

  switch (state.mode) {
    case Rainbow:
      for (int i =0; i<num_leds; i++) {
        leds[i] = CHSV(rainbow_counter + i * 2, 255, 255);
      }
      rainbow_counter++;
      break;

    case Color:
      for (int i = 0; i<num_leds; i++) {
        leds[i].red = state.red;
        leds[i].green = state.green;
        leds[i].blue = state.blue;
      }
      break;
  }

  FastLED.setBrightness(state.brightness);
  FastLED.setTemperature(state.temperature);
  if (need_update_led) {
    FastLED.show();
    FastLED.delay(20);
    need_update_led = false;
  }
}

void send(State &state, PacketType type, Function command, AsyncClient *client) {
  Packet packet;
  packet.type = type;
  packet.command = command;

  size_t state_buffer_size = 0;
  state_serialize(state, packet.data, state_buffer_size);

  char buffer[PACKET_MAX_SIZE];
  size_t buffer_size = 0;
  parser.serialize(packet, state_buffer_size, buffer, buffer_size);

  client->write(buffer, buffer_size);
}
