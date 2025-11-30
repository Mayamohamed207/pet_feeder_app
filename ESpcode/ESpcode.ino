// Enable Firebase features
#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>
#include <FirebaseJson.h>   // for FirebaseJson & FirebaseJsonData

// --------- CREDENTIALS (EDIT THESE) ----------
#define WIFI_SSID       "TALALEMARA 4453"
#define WIFI_PASSWORD   "HabibaElSabb"

#define WEB_API_KEY     "AIzaSyAEtnlCSUwfOd7-q-gRlCpekltH9Rrc-9w"
#define DATABASE_URL    "https://pet-feed-192ef-default-rtdb.europe-west1.firebasedatabase.app"

#define USER_EMAIL      "talal@feeder.com"
#define USER_PASS       "123456"
// --------------------------------------------

// Forward declarations
void processData(AsyncResult &aResult);

// Auth object
UserAuth user_auth(WEB_API_KEY, USER_EMAIL, USER_PASS);

// Firebase components
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);
RealtimeDatabase Database;

// Periodic status updates
unsigned long lastStatusSend = 0;
const unsigned long statusInterval = 30000; // 30 seconds

// Simple polling of command node
unsigned long lastCommandCheck = 0;
const unsigned long commandInterval = 2000; // 2 seconds

void setup() {
  Serial.begin(115200);
  delay(1000);

  // -------- WiFi ----------
  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nWiFi connected");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  // -------- TLS client ----
  ssl_client.setInsecure();               // for testing only
  ssl_client.setConnectionTimeout(1000);
  ssl_client.setHandshakeTimeout(5);

  // -------- Firebase app ---
  initializeApp(aClient, app, getAuth(user_auth), processData, "authTask");
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);
}

void loop() {
  // Keep Firebase internals running
  app.loop();

  static bool dbStarted = false;

  // Start DB work once auth is ready
  if (app.ready() && !dbStarted) {
    dbStarted = true;

    Serial.println("Firebase app is ready, sending initial status...");

    // Build JSON status as string (not FirebaseJson pointer)
    FirebaseJson j;
    j.set("online", true);
    j.set("lastUpdate", (int)(millis() / 1000));
    String payload;
    j.toString(payload, true);   // compact JSON string

    // Send initial status
    Database.set(aClient, "/devices/esp1/status", payload, processData, "set_initial_status");
  }

  if (app.ready()) {
    unsigned long now = millis();

    // Periodic status update
    if (now - lastStatusSend >= statusInterval) {
      lastStatusSend = now;

      FirebaseJson j;
      j.set("online", WiFi.status() == WL_CONNECTED);
      j.set("lastUpdate", (int)(now / 1000));
      String payload;
      j.toString(payload, true);

      Database.set(aClient, "/devices/esp1/status", payload, processData, "set_periodic_status");
    }

    // Poll command node
    if (now - lastCommandCheck >= commandInterval) {
      lastCommandCheck = now;
      Database.get(aClient, "/devices/esp1/command", processData, "get_command");
    }
  }

  delay(50);
}

// Called for DB operations (set, get, etc.)
void processData(AsyncResult &aResult) {
  if (!aResult.isResult()) return;

  if (aResult.isError()) {
    Serial.printf("Error task: %s, msg: %s, code: %d\n",
                  aResult.uid().c_str(),
                  aResult.error().message().c_str(),
                  aResult.error().code());
    return;
  }

  // Log raw payload
  Serial.printf("Task: %s, payload: %s\n",
                aResult.uid().c_str(),
                aResult.c_str());

  // If this was a command read, parse it
  if (aResult.uid() == "get_command") {
    // Expect JSON like: {"action":"FEEDNOW"}
    FirebaseJson data;
    data.setJsonData(aResult.c_str());

    FirebaseJsonData result;
    String path = "action";

    if (data.get(result, path)) {   // new API: get(FirebaseJsonData&, path)
      if (result.typeNum == FirebaseJson::JSON_STRING) {
        String action = result.to<String>();
        Serial.printf("Command action: %s\n", action.c_str());

        if (action == "FEEDNOW") {
          // TODO: your feeder GPIO here
          // digitalWrite(FEED_PIN, HIGH);
          // delay(1000);
          // digitalWrite(FEED_PIN, LOW);
          Serial.println("Feeding now!");

          // Clear command after handling
          FirebaseJson clearJson;
          clearJson.set("action", "");
          String clearPayload;
          clearJson.toString(clearPayload, true);

          Database.set(aClient,
                       "/devices/esp1/command",
                       clearPayload,
                       processData,
                       "clear_command");
        }
      } else {
        Serial.println("Field 'action' exists but is not a string");
      }
    } else {
      Serial.println("No 'action' field in command");
    }
  }
}
