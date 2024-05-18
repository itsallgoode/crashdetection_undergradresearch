// This is for an ESP32 paired with an MPU6050 Accelerometer

#include <Wire.h>
#include <MPU6050.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

MPU6050 accelerometer;

#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define CHARACTERISTIC_UUID "abcdef12-3456-7890-abcd-ef1234567890"


BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;


const float calibrationSlope = 0.9286414690675697;
const float calibrationIntercept = 7.72530754145125 - 7 + 1;
const float crashMinThresholdX = 45;
const float crashMaxThresholdX = 135;
const float crashMinThresholdY = 45;
const float crashMaxThresholdY = 135;

void setup() {
    Serial.begin(115200);
    Wire.begin();
    accelerometer.initialize();
    if (!accelerometer.testConnection()) {
        Serial.println("MPU6050 connection failed");
        while (1);
    }
    Serial.println("MPU6050 connection successful");

    BLEDevice::init("ESP32_BLE_Accelerometer");
    pServer = BLEDevice::createServer();
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);
    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    Serial.println("Waiting for a client connection to notify...");
}

float normalizeAngle(float angle) {
    while (angle < 0) angle += 360;
    while (angle >= 360) angle -= 360;
    return angle;
}

float calibrateAngle(float rawAngle) {
    return calibrationSlope * rawAngle + calibrationIntercept;
}

void loop() {
    // Read the raw accelerometer values
    int16_t ax, ay, az;
    accelerometer.getAcceleration(&ax, &ay, &az);
    float axg = ax / 16384.0;
    float ayg = ay / 16384.0;
    float azg = az / 16384.0;

    // Calculate the angles for the x and y axis
    float rawAngleX = atan2(ayg, azg) * 180.0 / PI;
    float rawAngleY = atan2(axg, azg) * 180.0 / PI;
    
    // Calibrate and normalize angles based on the original code provided
    float calibratedAngleX = calibrateAngle(rawAngleX);
    float calibratedAngleY = calibrateAngle(rawAngleY);
    float finalAngleX = normalizeAngle(calibratedAngleX);
    float finalAngleY = normalizeAngle(calibratedAngleY);

    // Crash detection logic based on original thresholds
    bool crashDetected = (finalAngleX < crashMinThresholdX || finalAngleX > crashMaxThresholdX || 
                          finalAngleY < crashMinThresholdY || finalAngleY > crashMaxThresholdY);

    // Format the data as a comma-separated string
    char dataString[100];
    snprintf(dataString, sizeof(dataString), "x:%.2f,y:%.2f,crash:%d", finalAngleX, finalAngleY, crashDetected ? 1 : 0);

    // Notify the BLE client with the new data
    if (pServer->getConnectedCount() > 0) {
        pCharacteristic->setValue(dataString);
        pCharacteristic->notify();
    }

    delay(100); // Delay for demonstration purposes. Adjust as needed for your application.
}
