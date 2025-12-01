#include <Servo.h>

Servo myServo;

// CONFIGURATION
const int INPUT_PIN = 7; // Connect this to ESP8266 D2
const int SERVO_PIN = 8; // Connect Servo Signal here

// ANGLES (Adjust for your box)
const int CLOSED_POS = 90; 
const int OPEN_POS = 5;

// Variables
int currentAngle = CLOSED_POS;
bool isFeeding = false;

void setup() {
  Serial.begin(9600);
  
  // Setup Input
  pinMode(INPUT_PIN, INPUT); 
  
  // Setup Servo
  myServo.attach(SERVO_PIN);
  myServo.write(CLOSED_POS);
  delay(500);
  // Optional: Detach to save power/noise when idle
  myServo.detach(); 
  
  Serial.println("Arduino Ready. Waiting for ESP signal...");
}

void loop() {
  // Read the signal from ESP
  int signal = digitalRead(INPUT_PIN);

  // If ESP says GO (HIGH)
  if (signal == HIGH && !isFeeding) {
    Serial.println("Signal Received! Feeding...");
    performFeeding();
  }
}

void performFeeding() {
  isFeeding = true;
  myServo.attach(SERVO_PIN); // Wake up servo
  
  // 1. OPEN
  Serial.println("Opening...");
  // Smooth opening
  for (int pos = CLOSED_POS; pos >= OPEN_POS; pos -= 1) { 
    myServo.write(pos);
    delay(15); // Speed control
  }
  
  // 2. WAIT
  delay(1000); // Keep open for 1 second
  
  // 3. CLOSE
  Serial.println("Closing...");
  // Smooth closing
  for (int pos = OPEN_POS; pos <= CLOSED_POS; pos += 1) { 
    myServo.write(pos);
    delay(15);
  }
  
  // 4. FINISH
  delay(500); // Wait for movement to finish
  myServo.detach(); // Relax servo
  isFeeding = false;
  
  Serial.println("Done. Waiting for next signal.");
}