#include <DHT.h>
#include <MQTT.h>
#include <ESP8266WiFi.h>
#include <Adafruit_CCS811.h>
#include <ArduinoJson.h>

#define NETWORK_SSID "3DS302"
#define NETWORK_PASSWORD "3eNgEPEt"
#define NETWORK_CONNECTION_CHECK_DELAY_MS 500
#define MQTT_SERVER_ADDRESS "192.168.1.104"
#define MQTT_SERVER_PORT 1883
#define MQTT_CLIENT_ID "SkyvaMQTTClient"
#define MQTT_TOPIC_NAME "measurements"
#define MQTT_LOGS_TOPIC_NAME "logs"

#define DHT_PIN D3
#define DHT_TYPE DHT11

#define PARTICLE_SENSOR_PIN D4

#define CCS_DEVICE_ADDR 0x5B

#define SENSOR_READ_THRESHOLD_MS 10000
#define INITIAL_DELAY 5000

#define PARTICLE_SENSOR_STATUS_BITSHIFT 0
#define TEMPERATURE_SENSOR_STATUS_BITSHIFT 8
#define CO2_SENSOR_STATUS_BITSHIFT 16

#define JSON_BUFFER_SIZE 256

enum SensorStatus
{
  SENSOR_STATUS_OK = 0,
  SENSOR_STATUS_NOT_CONNECTED = 1,
  SENSOR_STATUS_FAULTED = 2,
};

struct SensorsData
{
  float ParticleConcentration;
  float Temperature;
  float Humidity;
  uint16_t CO2Concentration;
  uint16_t TVOCConcentration;

  // unsigned long - 0x__CCTTPP
  // P: particle sensor status
  // T: temp & humidity sensor status
  // C: CO2 & TVOC sensor status
  // _: unused
  uint32_t SensorStatus;
};

static WiFiClient s_WIFIClient;
static MQTTClient s_MQTTClient;

static DHT s_DHT(DHT_PIN, DHT_TYPE);
static Adafruit_CCS811 s_CCS;

static unsigned long s_ParticleSensorLowPulseLength = 0;

static SensorStatus retrieveParticleSensorData(float *result)
{
  const float ratio = (float)s_ParticleSensorLowPulseLength / ((float)SENSOR_READ_THRESHOLD_MS * 10.0f);
  const float resultPcsPerFeet = 1.1f * pow(ratio, 3) - 3.8f * pow(ratio, 2) + 520.0f * ratio + 0.63f;
  *result = resultPcsPerFeet * 3531.47f;

  return SensorStatus::SENSOR_STATUS_OK;
}

static SensorStatus retrieveTemperatureSensorData(float *temperatureResult, float *humidityResult)
{
  *temperatureResult = s_DHT.readHumidity();
  *humidityResult = s_DHT.readTemperature();

  if (isnan(*temperatureResult) || isnan(*humidityResult))
    return SensorStatus::SENSOR_STATUS_FAULTED;

  return SensorStatus::SENSOR_STATUS_OK;
}

static SensorStatus retrieveCO2SensorData(uint16_t *co2Result, uint16_t *tvocResult, float temperature, float humidity, bool useEnvironmentalData)
{
  if (!s_CCS.available())
    return SensorStatus::SENSOR_STATUS_NOT_CONNECTED;

  if (useEnvironmentalData)
    s_CCS.setEnvironmentalData(humidity, temperature);

  if (s_CCS.readData())
    return SensorStatus::SENSOR_STATUS_FAULTED;

  *co2Result = s_CCS.geteCO2();
  *tvocResult = s_CCS.getTVOC();
  return SensorStatus::SENSOR_STATUS_OK;
}

static void retrieveSensorsData(SensorsData *result)
{
  const SensorStatus particleSensorStatus = retrieveParticleSensorData(&result->ParticleConcentration);
  const SensorStatus temperatureSensorStatus = retrieveTemperatureSensorData(&result->Temperature, &result->Humidity);
  const SensorStatus co2SensorStatus = retrieveCO2SensorData(
      &result->CO2Concentration,
      &result->TVOCConcentration,
      result->Temperature,
      result->Humidity,
      temperatureSensorStatus == SensorStatus::SENSOR_STATUS_OK);

  result->SensorStatus = ((particleSensorStatus << PARTICLE_SENSOR_STATUS_BITSHIFT) |
                          (temperatureSensorStatus << TEMPERATURE_SENSOR_STATUS_BITSHIFT) |
                          (co2SensorStatus << TEMPERATURE_SENSOR_STATUS_BITSHIFT));
}

static void setupNetwork()
{
  Serial.println(F("Connecting to the network..."));

  WiFi.begin(NETWORK_SSID, NETWORK_PASSWORD);
  while (WiFi.status() != WL_CONNECTED)
    delay(NETWORK_CONNECTION_CHECK_DELAY_MS);

  Serial.println(F("Connected to the network."));
}

static void setupMQTT()
{
  Serial.println(F("Connecting to the MQTT server..."));

  s_MQTTClient.begin(MQTT_SERVER_ADDRESS, MQTT_SERVER_PORT, s_WIFIClient);
  while (!s_MQTTClient.connect(MQTT_CLIENT_ID))
    delay(NETWORK_CONNECTION_CHECK_DELAY_MS);

  Serial.println(F("Connected to the MQTT server."));
}

static void setupDHT()
{
  Serial.println(F("Starting DHT11..."));

  s_DHT.begin();
}

static void setupCCS()
{
  Serial.println(F("Starting CCS811..."));

  if (!s_CCS.begin(CCS_DEVICE_ADDR))
  {
    Serial.println(F("Failed to start CCS811 sensor."));
    return;
  }

  Serial.println(F("Waiting for CCS811 available..."));
}

static void setupParticleSensor()
{
  Serial.println(F("Starting particle sensor..."));
  pinMode(PARTICLE_SENSOR_PIN, INPUT);
}

void setup()
{
  Serial.begin(115200);
  Serial.println();
  Serial.println(F("Starting driver..."));

  setupNetwork();
  setupMQTT();
  setupDHT();
  setupParticleSensor();
  setupCCS();

  Serial.println(F("Executing post-startup delay..."));
  delay(INITIAL_DELAY);
}

void loop()
{
  static unsigned long s_TimeoutStartTimestamp;
  static unsigned long s_StartTime;
  static char s_JSONBuffer[JSON_BUFFER_SIZE];

  s_MQTTClient.loop();

  const unsigned long currentTime = millis();
  s_ParticleSensorLowPulseLength += pulseIn(PARTICLE_SENSOR_PIN, LOW);

  if (currentTime - s_StartTime < SENSOR_READ_THRESHOLD_MS)
    return;

  SensorsData sensorsData{};
  retrieveSensorsData(&sensorsData);

  JsonDocument json;
  json[F("particle_concentration")] = sensorsData.ParticleConcentration;
  json[F("temperature")] = sensorsData.Temperature;
  json[F("humidity")] = sensorsData.Humidity;
  json[F("co2_concentration")] = sensorsData.CO2Concentration;
  json[F("tvoc_concentration")] = sensorsData.TVOCConcentration;
  json[F("sensor_status")] = sensorsData.SensorStatus;
  serializeJson(json, s_JSONBuffer);

  if (s_MQTTClient.publish(MQTT_TOPIC_NAME, s_JSONBuffer))
  {
    Serial.print(F("Published sensor data to MQTT, timestamp: "));
    Serial.println(currentTime);
  }
  else
  {
    Serial.println(F("Failed to publish sensor data to MQTT."));
  }

  s_StartTime = currentTime;
  s_ParticleSensorLowPulseLength = 0;
}
