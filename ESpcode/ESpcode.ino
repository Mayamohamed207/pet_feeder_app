// Enable Firebase features
#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>
#include <FirebaseJson.h>     
#include <time.h>             

// --------- CREDENTIALS ----------
#define WIFI_SSID       "TALALEMARA 4453"
#define WIFI_PASSWORD   "HabibaElSabb"

#define WEB_API_KEY     "AIzaSyAEtnlCSUwfOd7-q-gRlCpekltH9Rrc-9w"
#define DATABASE_URL    "https://pet-feed-192ef-default-rtdb.europe-west1.firebasedatabase.app"

#define USER_EMAIL      "talal@feeder.com"
#define USER_PASS       "123456"

// GPIO Pin for Feeder
#define FEED_PIN D1 

// Forward declarations
void processData(AsyncResult &aResult);

UserAuth user_auth(WEB_API_KEY, USER_EMAIL, USER_PASS);
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);
RealtimeDatabase Database;

unsigned long lastStatusSend = 0;
const unsigned long statusInterval = 30000; // 30 seconds

unsigned long lastCommandCheck = 0;
// FIX 1: Increased to 10 seconds to stop "-118 cancelled" errors
const unsigned long commandInterval = 10000; 

void setup() {
  Serial.begin(115200);
  pinMode(FEED_PIN, OUTPUT);
  digitalWrite(FEED_PIN, LOW); 
  delay(1000);

  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nWiFi connected");
  
  ssl_client.setInsecure(); 

  initializeApp(aClient, app, getAuth(user_auth), processData, "authTask");
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);
}

void loop() {
  app.loop();

  static bool dbStarted = false;

  if (app.ready() && !dbStarted) {
    dbStarted = true;
    FirebaseJson j;
    j.set("online", true);
    j.set("lastUpdate", (int)(millis() / 1000));
    String payload;
    j.toString(payload, true);
    Database.set(aClient, "/devices/esp1/status", object_t(payload), processData, "initial_status");
  }

  if (app.ready()) {
    unsigned long now = millis();

    // 1. Status Update
    if (now - lastStatusSend >= statusInterval) {
      lastStatusSend = now;
      FirebaseJson j;
      j.set("online", WiFi.status() == WL_CONNECTED);
      j.set("lastUpdate", (int)(now / 1000));
      String payload;
      j.toString(payload, true);
      Database.set(aClient, "/devices/esp1/status", object_t(payload), processData, "periodic_status");
    }

    // 2. Check Command (Slower now)
    if (now - lastCommandCheck >= commandInterval) {
      lastCommandCheck = now;
      // We read the command node
      Database.get(aClient, "/devices/esp1/command", processData, "get_command");
    }
  }
  
  delay(100); 
}

void processData(AsyncResult &aResult) {
  if (!aResult.isResult()) return;

  // Print raw data for debugging
  Serial.printf("Received: %s\n", aResult.c_str());

  // FIX 2: ROBUST STRING SCANNING
  // Instead of checking UID or parsing complex JSON, we just look for the text.
  String data = aResult.c_str();

  // Check if the data contains "FEED_NOW" (Using the underscore matching your logs)
  if (data.indexOf("FEED_NOW") > -1) {
    
    Serial.println(">>> FEED COMMAND DETECTED! <<<");
    
    // Run Motor
    digitalWrite(FEED_PIN, HIGH);
    delay(1000);  
    digitalWrite(FEED_PIN, LOW);
    
    Serial.println("Fed successfully. Clearing command...");

    // Clear the command so it doesn't feed again
    FirebaseJson clearJson;
    clearJson.set("action", "");
    String clearPayload;
    clearJson.toString(clearPayload, true);
    
    // We use a different task name so we don't trigger the feeder on the clear confirmation
    Database.set(aClient, "/devices/esp1/command", object_t(clearPayload), processData, "clear_done");
  }
}