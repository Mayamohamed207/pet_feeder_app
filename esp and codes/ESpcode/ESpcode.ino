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

// --- USER CONFIGURATION ---
// Validated against your JSON structure
#define TARGET_UID      "Mdnxn4hW6vcW7f1iKIARPpm8kaH2" 

// Path to listen for App Commands: /users/{uid}/commands/dispenseNow
String userCommandPath = "/users/" + String(TARGET_UID) + "/commands/dispenseNow";

// Path to update ESP Status: /devices/esp1/command
String deviceStatusPath = "/devices/esp1/command";

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
const unsigned long commandInterval = 5000; // Check every 5 seconds

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

  // --- DEBUG PATH PRINTING ---
  Serial.println("\n-------------------------------------------");
  Serial.println("--- CHECK THIS PATH IN FIREBASE ---");
  Serial.println(userCommandPath); 
  Serial.println("-------------------------------------------\n");
}

void loop() {
  app.loop();

  static bool dbStarted = false;

  // 1. Initial Status (Heartbeat to /devices/esp1/status)
  if (app.ready() && !dbStarted) {
    dbStarted = true;
    FirebaseJson j;
    j.set("online", true);
    j.set("lastUpdate", (int)(millis() / 1000));
    
    String payload;
    j.toString(payload, true);
    Database.set(aClient, "/devices/esp1/status", object_t(payload), processData, "set_initial_status");
  }

  if (app.ready()) {
    unsigned long now = millis();

    // 2. Periodic Status Update
    if (now - lastStatusSend >= statusInterval) {
      lastStatusSend = now;

      FirebaseJson j;
      j.set("online", WiFi.status() == WL_CONNECTED);
      j.set("lastUpdate", (int)(now / 1000));
      
      String payload;
      j.toString(payload, true);
      Database.set(aClient, "/devices/esp1/status", object_t(payload), processData, "set_periodic_status");
    }

    // 3. Poll Command (Reads from User Path)
    if (now - lastCommandCheck >= commandInterval) {
      lastCommandCheck = now;
      Database.get(aClient, userCommandPath, processData, "check_feed");
    }
  }
  
  delay(100); 
}

void processData(AsyncResult &aResult) {
  if (!aResult.isResult()) return;

  String taskName = aResult.uid();
  String data = aResult.c_str();

  // Print raw data for debugging
  Serial.printf("Task: %s | Data: %s\n", taskName.c_str(), data.c_str());

  // DEBUG HELP: If data is empty, warn the user
  if (data.length() == 0 || data == "null") {
    if (taskName.startsWith("task_") || taskName == "check_feed") {
       Serial.println(">>> WARNING: Received EMPTY data. The path might be wrong or empty in Firebase.");
    }
    return;
  }

  // 1. Check for "pending" status in ANY task result
  // We removed the 'if uid == check_feed' restriction to fix the random task ID issue
  if (data.indexOf("pending") > -1) {
    
    Serial.println(">>> APP REQUESTED FEEDING! <<<");

    // --- STEP A: Tell Database we are starting ---
    FirebaseJson statusJson;
    statusJson.set("action", "FEEDING_IN_PROGRESS");
    String statusPayload;
    statusJson.toString(statusPayload, true);
    Database.set(aClient, deviceStatusPath, object_t(statusPayload), processData, "status_update_start");
    
    // --- STEP B: MOTOR ACTION ---
    digitalWrite(FEED_PIN, HIGH);
    delay(1000);  // Feed for 1 second
    digitalWrite(FEED_PIN, LOW);
    // --------------------
    
    Serial.println("Fed successfully. Updating status...");

    // --- STEP C: Tell Database we are finished ---
    statusJson.set("action", "IDLE"); // Reset device status
    statusJson.toString(statusPayload, true);
    Database.set(aClient, deviceStatusPath, object_t(statusPayload), processData, "status_update_end");

    // --- STEP D: Mark Order as Completed ---
    String userStatusPath = userCommandPath + "/status";
    // Use object_t to send the raw string "completed"
    Database.set(aClient, userStatusPath, object_t("\"completed\""), processData, "mark_complete");
  }
}