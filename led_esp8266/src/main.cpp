#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>

const char* ssid      = "MikroTik-2GHz";
const char* password  = "OuroBoroS";

const int redPinA = D0;
const int redPinB = D1;

volatile uint8_t red = 255;
volatile uint8_t green = 244;
volatile uint8_t blue = 229;
volatile uint8_t brightness = 0;
int lastRedEncoded = 0;

WiFiServer server(12345);

// Forward declarations
void updateRedEncoder();
void updateEncoder(int pinA, int pinB, int &lastEncoded, volatile uint8_t &value);

void setup() {
  Serial.begin(9600);
  delay(10);
  Serial.println("\n");

  WiFi.begin(ssid, password);
  Serial.print("Connecting to ");
  Serial.print(ssid);
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

  // Set encoders pins
  pinMode(redPinA, INPUT_PULLUP);
  pinMode(redPinB, INPUT_PULLUP);
}

void loop() {
  MDNS.update();

  WiFiClient client = server.accept();
  if (client) {
    Serial.println("New client connected");
    while (client.connected()) {
      while(client.available() > 0) {
        char c = client.read();
        Serial.println(c);
      }
    delay(10);
    }
    client.stop();
    Serial.println("Client disconnected");
  }
  updateRedEncoder();
}

void updateRedEncoder() {
  static int lastRedPos = -1;
  updateEncoder(redPinA, redPinB, lastRedEncoded, red);
  if (red != lastRedPos) {
    Serial.print("Red: ");
    Serial.println(red);
    lastRedPos = red;
  }
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
