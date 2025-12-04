#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h> // For Descriptors

// Define the LED Pin
const int ledPin = 2; 

// Define UUIDs for your custom Service and Characteristic
// Use a generator (like uuidgenerator.net) to create unique 128-bit UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Create a class to handle the Characteristic Write event
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string value = pCharacteristic->getValue();

        if (value.length() > 0) {
            // Read the first character sent from the client
            char command = value[0];

            Serial.print("Received Command: ");
            Serial.println(command);

            if (command == '1') {
                digitalWrite(ledPin, HIGH); // Turn LED ON
                Serial.println("LED ON");
            } else if (command == '0') {
                digitalWrite(ledPin, LOW);  // Turn LED OFF
                Serial.println("LED OFF");
            }
        }
    }
};

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW); // LED starts OFF

  // 1. Initialize BLE Device and set its name
  BLEDevice::init("BLE_LED_AT_Demo");

  // 2. Create the BLE Server
  BLEServer *pServer = BLEDevice::createServer();

  // 3. Create the Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // 4. Create a Characteristic with Read/Write properties
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
                                       
  // Set the characteristic's initial value and register the callback
  pCharacteristic->setValue("0"); // Default LED state
  pCharacteristic->setCallbacks(new MyCallbacks());

  // 5. Start the Service
  pService->start();

  // 6. Start Advertising (making the device discoverable)
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferredProcessors(0x06);  // helps with connection speed
  pAdvertising->setMaxPreferredProcessors(0x08);
  BLEDevice::startAdvertising();

  Serial.println("Waiting for a BLE Client to connect...");
}

void loop() {
    // The control logic is handled inside the MyCallbacks::onWrite function.
    // The main loop can be used for other tasks or left empty.
    delay(200);
}