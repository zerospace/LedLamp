#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include "WiFiConfig.h"
#include "packet/Packet.h"
#include <memory.h>
#include "State.h"

const int num_leds = 60;
const int led_pin = D7;

const int red_pin_A = D0;
const int red_pin_B = D1;

State state;
CRGB leds[num_leds];
WiFiServer server(12345);
Parser parser;

byte rainbow_counter;

// Forward declarations
void updateEncoder(int pinA, int pinB, int &lastEncoded, volatile uint8_t &value);

void setup() {
  Serial.begin(9600);
  delay(10);
  Serial.println("\n");

  state.red = 255;
  state.green = 244;
  state.blue = 229;
  state.brightness = 128;
  state.mode = Color;
  state.temperature = Tungsten100W;

  FastLED.addLeds<WS2812, led_pin, GRB>(leds, num_leds).setCorrection(TypicalSMD5050);

  pinMode(red_pin_A, INPUT_PULLUP);
  pinMode(red_pin_B, INPUT_PULLUP);

  WiFi.begin(SSID, PASSWORD);
  Serial.print("Connecting to ");
  Serial.print(SSID);
  Serial.println(" ...");

  int i = 0;
  while(WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(++i);
    Serial.print(" ");
  }

  Serial.println("\n");
  Serial.println("Connection established!");
  Serial.print("IP address:\t");
  Serial.println(WiFi.localIP());

  if (!MDNS.begin("esp8266")) {
    Serial.println("Error setting up MDNS responder!");
  }
  Serial.println("mDNS responder started");
  MDNS.addService("lamp", "tcp", 12345);

  server.begin();
}

void loop() {
  MDNS.update();

  WiFiClient client = server.accept();
  if (client) {
    Serial.println("New client connected");

    size_t length = 0;
    char buffer[PACKET_MAX_SIZE];

    while (client.connected()) {
      if(client.available()) {
        buffer[length++] = client.read();
        
        Packet packet;
        if (parser.parse(buffer, length, &packet) == 0) {
          length = 0;
          memset(buffer, 0, PACKET_MAX_SIZE);
          switch (packet.type) {
            case Command:
              switch (packet.command) {
                case SetState:
                  deserialize_state(packet.data, state);
                  Serial.println(state.red);
                  break;
                  
                case GetState:
                  Packet p;
                  p.type = Response;
                  p.command = GetState;

                  size_t state_buffer_size = 0;
                  state_serialize(state, p.data, state_buffer_size);

                  char buffer[PACKET_MAX_SIZE];
                  size_t buffer_size = 0;
                  parser.serialize(p, state_buffer_size, buffer, buffer_size);

                  client.write(buffer, buffer_size);
                  break;
              }
              break;

            case Response:
              break;
          }
        }
      }
    delay(10);
    }
    client.stop();
    Serial.println("Client disconnected");
  }

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
  FastLED.show();
  FastLED.delay(8);
}

void updateEncoder(int pinA, int pinB, int &lastEncoded, volatile uint8_t &value) {
  int msb = digitalRead(pinA); // most significant bit
  int lsb = digitalRead(pinB); // least significnt bit

  int encoded = (msb << 1) | lsb; // convert to single number
  int sum = (lastEncoded << 2) | encoded; 

  if (sum == 0b1101 || sum == 0b0100 || sum == 0b0010 || sum == 0b1011) {
    value = min(value + 1, 255);
  }

  if (sum == 0b1110 || sum == 0b0111 || sum == 0b0001 || sum == 0b1000) {
    value = max(0, value - 1);
  }

  lastEncoded = encoded;
}
