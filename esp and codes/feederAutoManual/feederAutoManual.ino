// --- PIN DEFINITION ---
const int signalPin = D2; // Connect this to Arduino Input Pin

// Feeding control flags
bool feeding = false;
unsigned long feedingStartTime = 0;
unsigned long lastFeedTime = 0;

// Auto-feed interval
const unsigned long FEED_INTERVAL = 30000; // 30 seconds

// Signal Duration (How long to hold the pin HIGH)
// 1000ms (1 second) is plenty of time for Arduino to detect it
const unsigned long SIGNAL_DURATION = 1000; 

void startFeeding() {
  if (feeding) return; // Prevent double trigger
  
  feeding = true;
  feedingStartTime = millis();
  
  // --- ACTION: SEND HIGH SIGNAL ---
  digitalWrite(signalPin, HIGH); 
  Serial.println("Signal Sent: HIGH");
}

void updateSignal() {
  // If we are not currently feeding, do nothing
  if (!feeding) return;

  // Check if the signal duration has passed
  if (millis() - feedingStartTime >= SIGNAL_DURATION) {
    
    // --- ACTION: TURN SIGNAL LOW ---
    digitalWrite(signalPin, LOW);
    
    feeding = false;
    lastFeedTime = millis();
    Serial.println("Signal Ended: LOW");
    Serial.println("Waiting for next cycle...");
  }
}

void setup() {
  Serial.begin(115200); 
  
  // Initialize Signal Pin
  pinMode(signalPin, OUTPUT);
  digitalWrite(signalPin, LOW); // Ensure it starts LOW

  lastFeedTime = millis(); // Start the timer count now

  Serial.println("ESP8266 Signal Sender Ready.");
  Serial.println("Type '1' to send signal manually.");
}

void loop() {
  // Check for Manual Command via Serial
  if (Serial.available()) {
    char c = Serial.read();
    if (c == '1') {
      Serial.println("Manual Command Received");
      startFeeding();
    }
  }

  // Check for Auto-Feed Timer
  if (!feeding && millis() - lastFeedTime >= FEED_INTERVAL) {
    Serial.println("Timer Triggered");
    startFeeding();
  }

  // Update Signal State (Turn off after 1 second)
  updateSignal();
  
  delay(10); // Watchdog safety
}