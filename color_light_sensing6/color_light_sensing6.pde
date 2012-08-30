/* 
 * Color Light Calibration
 * Ryan Greenberg
 * 24 November 2009
 *
 * Connect a photosensor to analog inputs 0, 1, and 2.
 */

#include <EEPROM.h>

// EEPROM Read/Write helper from http://www.arduino.cc/playground/Code/EEPROMWriteAnything
template <class T> int EEPROM_readAnything(int ee, T& value)
{
    byte* p = (byte*)(void*)&value;
    int i;
    for (i = 0; i < sizeof(value); i++)
	  *p++ = EEPROM.read(ee++);
    return i;
}

boolean debug = true;

char color;

int photoPins[] = {0, 1, 2}; // Arduino pins that photosensors are connected to
const int numPins = sizeof(photoPins) / sizeof(int); // Number of photosensors connected to Arduino
const int sampleWindow = 10; // Number of readings to use to evaluate the high or low value for a sensor
int sampleDelay = 50; // ms to delay between sample readings
int sensingDelay = 100; // ms to delay between readings to determine pour color. Used to handle macro jitter
int delayBetweenPours = 1000; /// ms to delay after sensing a color before it can be sensed again

int vals[numPins] = {0,0,0}; // Single reading from each sensor
float current[numPins] = {0,0,0}; // Averaged reading from each sensor using sampleWindow and sampleDelay
int photoStates[numPins] = {0,0,0}; // Current HIGH (1) or LOW (0) state for a given photosensor
int sampleVals[numPins * sampleWindow]; // Sample of readings from each sensor determined by sampleWindow and numPins

// Calibration values for each sensor
float lows[numPins] = {0,0,0};
float whites[numPins] = {0,0,0};
float reds[numPins] = {0,0,0};
float yellows[numPins] = {0,0,0};
float blues[numPins] = {0,0,0};

float whitesPercent[numPins] = {0,0,0};
float redsPercent[numPins] = {0,0,0};
float yellowsPercent[numPins] = {0,0,0};
float bluesPercent[numPins] = {0,0,0};

float whitesSum = 0.0;
float redsSum = 0.0;
float yellowsSum = 0.0;
float bluesSum = 0.0;

float baseline = 0; // Sum of all photosensors readings at low value
float ranges[numPins] = {0,0,0};
float thresholds[numPins] = {0,0,0};
float tolerance = .015;

// Direction to scale the initial reading when creating a threshold. If the initial
// reading is taken in a LOW state (no light), this should be 1, indicating that the
// threshold is created in a positive direciton. If the initial reading is in a HIGH
// state (light activated), this should be -1, indicating that the threshold is created
// in a negative direction.
float thresholdScale = .10; // pecentage to use when scaling initial reading to set threshold level

// TODO It might be useful to use map for reading test values
// http://arduino.cc/en/Reference/Map

void setup() {
  Serial.begin(9600);
  
  // Load calibrated data from EEPROM
  Serial.println("Reading calibration values from EEPROM...");
  
  char calibratedFlag;
  EEPROM_readAnything(0, calibratedFlag);
  if (calibratedFlag == 'C') {
     Serial.println("Found stored calibration readings...");
    int start = 1;
    start += EEPROM_readAnything(start, lows);
    start += EEPROM_readAnything(start, whites);
    start += EEPROM_readAnything(start, reds);
    start += EEPROM_readAnything(start, yellows);
    start += EEPROM_readAnything(start, blues);
    if (debug) {
      Serial.println("Loaded calibrated values.");
    }
  } else {
    if (debug) {
      Serial.println("Error: could not find calibration values. Re-run calibration");
    }
  }
  
  // Make sure that all calibration values were recorded properly
  if (debug) {
    Serial.println("CALIBRATION VALUES");
    Serial.println("\t0\t1\t2");
  // TODO It would be nice to have an array of pointers to the color to make this less verbose
  //float *colors[5] = { &lows, &whites, &reds, &yellows, &blues };
  // The post calibration output should look something like this:
  //               0     1     2
  //    LOW      412   532   800
  //    WHITE    412   532   800
  //    RED      412   532   800
  //    YELLOW   412   532   800
  //    BLUE     412   532   800
  
  Serial.print("LOW\t");
  for (int i = 0; i < numPins; i++) {
    Serial.print(lows[i]);
    Serial.print("\t");
  }
  Serial.println();
  
  Serial.print("WHITE\t");
  for (int i = 0; i < numPins; i++) {
    Serial.print(whites[i]);
    Serial.print("\t");
  }
  Serial.println();
  
  Serial.print("RED\t");
  for (int i = 0; i < numPins; i++) {
    Serial.print(reds[i]);
    Serial.print("\t");
  }
  Serial.println();

  Serial.print("YELLOW\t");
  for (int i = 0; i < numPins; i++) {
    Serial.print(yellows[i]);
    Serial.print("\t");
  }
  Serial.println();

  Serial.print("BLUE\t");
  for (int i = 0; i < numPins; i++) {
    Serial.print(blues[i]);
    Serial.print("\t");
  }
  Serial.println();
  }

  // Set threshold and range values
  for (int i = 0; i < numPins; i++) {
    ranges[i] = abs(whites[i] - lows[i]);
    thresholds[i] = abs(whites[i] - lows[i]) * thresholdScale;
  }
  
  // Sum baseline readings and color value readings for use
  // in later calculations
  for (int i = 0; i < numPins; i++) {
    baseline += lows[i];
    whitesSum += whites[i];
    redsSum += reds[i];
    yellowsSum += yellows[i];
    bluesSum += blues[i];
  }

  // Use white, red, yellow, and blue readings to calculate
  // arrays based on their usage of percentage of total available light
  for (int i = 0; i < numPins; i++) {
    // Each sensor has a calculated value that is equal to
    // reading / (sum of all readings - sum of baseline readings);
    whitesPercent[i] = reds[i] / (redsSum - baseline);
    redsPercent[i] = reds[i] / (redsSum - baseline);
    yellowsPercent[i] = reds[i] / (redsSum - baseline);
    bluesPercent[i] = reds[i] / (redsSum - baseline);
  }
  if (debug) {
    Serial.println("Calculated percentage-based values for each sensor");
  }

  Serial.println("ready");
}


void loop() { 
  sampleDelay = 0;
  samplePhotoSensors(sampleVals);
  photoSensorAverages(current, sampleVals);
  color = matchColor(current);
  if (color == 'x') {
    // No color detected
    // Serial.println("No color detected");
  } else {
    // Color detected
    // Serial.print("Color detected: ");
    delay(sensingDelay);
    samplePhotoSensors(sampleVals);
    photoSensorAverages(current, sampleVals);
    if (color == matchColor(current)) {
      // Confirmed color match
      Serial.print("c");
      Serial.println(color);
      delay(delayBetweenPours);
    }
  }

  // delay(50); // For smoothing purposes
}


// Take a series of readings from each photosensor determined by numPins and sampleWindow
void samplePhotoSensors (int *readings) {
  for (int n = 0; n < sampleWindow * numPins;) {
    for (int i = 0; i < numPins; i++) {
      readings[n] = analogRead(photoPins[i]);
      n++;
    }
    delay(sampleDelay);
  }
  
//  Serial.println("sampled sensors: ");
//  for (int n = 0; n < sampleWindow * numPins; n++) {
//      Serial.println(readings[n]);
//  }
}

void photoSensorAverages(float *destination, int *readings) {
  for (int i = 0; i < numPins; i++) {
//     Serial.print("Average for pin ");
//     Serial.println(i);
//     
    destination[i] = average(readings, i);
  }
}

// Returns the average for a specified pin in a set of readings
// For three photosensors using a 3 reading sample window, the
// readings array looks like this:
// [300,525,600,315,545,580,290,530,605]
//  1   2   3   1   2   3   1   2   3
float average (int *readings, int pin) {
    int sum = 0;
    for (int i = 0; i < numPins * sampleWindow; i++) {
      if (i % numPins == pin) {
        // i = 0 corresponds to pin 0
        // E.g. 0 % 3 = 0
//        Serial.print("\t");
//        Serial.println(readings[i]);
        sum += readings[i];
      }
    }
//     Serial.print("AVERAGE:\t");
//     Serial.println((float) sum / sampleWindow);
    return ((float) sum / sampleWindow);
}

float sum (float *readings) {
  float sum = 0;
  for (int i = 0; i < numPins; i++) {
    sum += readings[i];
  }
  return sum;
}

char matchColor(float *readings) {
// This checking approach relies heavily on the values given by the calibration. It is fragile and does not detect the
// right color with any frequency.

  // Calculate percentage of used light values for each pin
  float allLight = sum(readings); // Sum of photosensor readings
  float availableLight = allLight - baseline;
  float percents[numPins];
  for (int i = 0; i < numPins; i++) {
    percents[i] = readings[i] / availableLight;
  }

  // Check for white
  boolean isWhite = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in whites, then it's white
  for (int i = 0; i < numPins; i++) {
    if (!(percents[i] - tolerance < whitesPercent[i] && percents[i] + tolerance > whitesPercent[i])) {
      isWhite = false;
    }
  }
  if (isWhite) {
    return 'w';
  }

  // Check for red
  boolean isRed = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in reds, then it's red
  for (int i = 0; i < numPins; i++) {
    if (!(percents[i] - tolerance < redsPercent[i] && percents[i] + tolerance > redsPercent[i])) {
      isRed = false;
    }
  }
  if (isRed) {
    return 'r';
  }

  // Check for yellow
  boolean isYellow = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in yellows, then it's yellow
  for (int i = 0; i < numPins; i++) {
    if (!(percents[i] - tolerance < yellowsPercent[i] && percents[i] + tolerance > yellowsPercent[i])) {
      isYellow = false;
    }
  }
  if (isYellow) {
    return 'y';
  }
  
//  // Check for blue
//  Serial.println("BLUE");
  boolean isBlue = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in reds, then it's red
  for (int i = 0; i < numPins; i++) {
    if (!(percents[i] - tolerance < bluesPercent[i] && percents[i] + tolerance > bluesPercent[i])) {
      isBlue = false;
    }
  }
  if (isBlue) {
    return 'b';
  }
  
  // No color detected
  return 'x';
}
