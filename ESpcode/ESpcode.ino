// Enable Firebase features
#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>

// --------- CREDENTIALS (EDIT THESE) ----------
#define WIFI_SSID       "TALALEMARA 4453"
#define WIFI_PASSWORD   "HabibaElSabb"

#define WEB_API_KEY     "AIzaSyAEtnlCSUwfOd7-q-gRlCpekltH9Rrc-9w"
#define DATABASE_URL    "https://pet-feed-192ef-default-rtdb.europe-west1.firebasedatabase.app"

#define USER_EMAIL      "talal@feeder.com"   // must match a user in Firebase Auth
#define USER_PASS       "123456"             // that user's password
// --------------------------------------------

// Forward declarations
void processData(AsyncResult &aResult);
void processStream(AsyncResult &aResult);

// Auth object
UserAuth user_auth(WEB_API_KEY, USER_EMAIL, USER_PASS);

// Firebase components
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);
RealtimeDatabase Database;

// For periodic status updates
unsigned long lastStatusSend = 0;
const unsigned long statusInterval = 30000; // 30 seconds

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
  // Keep FirebaseClient internals running
  app.loop();

  static bool dbStarted = false;

  // Only start DB work once auth is ready
  if (app.ready() && !dbStarted) {
    dbStarted = true;

    Serial.println("Firebase app is ready, sending initial status and starting stream...");

    // Initial ONLINE status
    FirebaseJson json;
    json.set("online", true);
    json.set("lastUpdate", (int)(millis() / 1000));
    Database.set(aClient, "/devices/esp1/status", &json, processData, "set_initial_status");

    // Start listening to commands: /devices/esp1/command
    Database.stream(aClient, "/devices/esp1/command", processStream, "command_stream");
  }

  // Periodic status update
  if (app.ready()) {
    unsigned long now = millis();
    if (now - lastStatusSend >= statusInterval) {
      lastStatusSend = now;

      FirebaseJson json;
      json.set("online", WiFi.status() == WL_CONNECTED);
      json.set("lastUpdate", (int)(now / 1000));
      Database.set(aClient, "/devices/esp1/status", &json, processData, "set_periodic_status");
    }
  }

  delay(50);
}

// Called for normal DB operations (set, etc.)
void processData(AsyncResult &aResult) {
  if (!aResult.isResult()) return;

  if (aResult.isError()) {
    Serial.printf("Error task: %s, msg: %s, code: %d\n",
                  aResult.uid().c_str(),
                  aResult.error().message().c_str(),
                  aResult.error().code());
  } else if (aResult.available()) {
    Serial.printf("Task: %s, payload: %s\n",
                  aResult.uid().c_str(),
                  aResult.c_str());
  }
}

// Called when /devices/esp1/command changes
void processStream(AsyncResult &aResult) {
  if (!aResult.isStream()) return;
  if (!aResult.isStreamAvailable()) return;

  Serial.printf("Stream event: %s\n", aResult.c_str());

  FirebaseJson data;
  data.setJsonData(aResult.c_str());

  String action;
  if (data.get(action, "action") == 0) {
    Serial.printf("No 'action' field in command\n");
    return;
  }

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
    Database.set(aClient, "/devices/esp1/command", &clearJson, processData, "clear_command");
  }
}
