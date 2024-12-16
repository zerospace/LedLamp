#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <ESPAsyncTCP.h>
#include "WiFiConfig.h"
#include "packet/Packet.h"
#include <memory.h>
#include "State.h"
#include <NeoPixelBus.h>

const int num_leds = 60;

State state;
NeoPixelBus<NeoGrbFeature, NeoEsp8266BitBangWs2812xMethod> strip(num_leds, D7);
RgbColor currentColor(255, 244, 229);
float animationProgress = 0.0;
const float animationStep = 0.02;
AsyncServer server(12345);
Parser parser;

float rainbow_counter = 0.0;

// Forward declarations
void send(State &state, PacketType type, Function command, AsyncClient *client);

void setup() {
  Serial.begin(9600);
  delay(10);

  state.red = 255;
  state.green = 244;
  state.blue = 229;
  state.mode = Color;

  strip.Begin();
  strip.Show();

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
                animationProgress = 0.0;
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
        float hue = fmod(rainbow_counter + (float)i * 0.01, 1.0);
        HsbColor color(hue, 1.0, 1.0);
        strip.SetPixelColor(i, color);
      }
      rainbow_counter += 0.01;
      break;

    case Color:
      if (animationProgress  < 1.0) {
        currentColor = RgbColor::LinearBlend(currentColor, RgbColor(state.red, state.green, state.blue), animationProgress);
        animationProgress += animationStep;
      }
      for (int i = 0; i<num_leds; i++) {
        strip.SetPixelColor(i, currentColor);
      }
      break;
  }

  strip.Show();
  delay(20);
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
