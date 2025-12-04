#include <SoftwareSerial.h>

// Define pins for the virtual serial port
// RX (Pin 2) connects to HM-10 TX
// TX (Pin 3) connects to HM-10 RX
SoftwareSerial BTSerial(2, 3); 

void setup() {
  Serial.begin(9600);    // Monitor Speed
  BTSerial.begin(9600);  // HM-10 Default Speed
  Serial.println("Arduino with HM-10 Bridge Ready.");
  Serial.println("Type AT commands here:");
}

void loop() {
  // Read from HM-10 and send to Serial Monitor
  if (BTSerial.available()) {
    Serial.write(BTSerial.read());
  }

  // Read from Serial Monitor and send to HM-10
  if (Serial.available()) {
    BTSerial.write(Serial.read());
  }
}