/* 
 * Color Light Sensing (v5)
 * Gogh Bike by Ben Cohen, Ryan Greenberg, Joyce Tsai
 * 
 * Connect a photosensor under different colored films to analog inputs 0, 1, 2.
 * Using this program requires calibration values stored in the board EEPROM. Use color_light_calibration
 * to gather and store values.
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

char color;

int photoPins[] = {0, 1, 2}; // Arduino pins that photosensors are connected to
const int numPins = sizeof(photoPins) / sizeof(int); // Number of photosensors connected to Arduino
const int sampleWindow = 10; // Number of readings to use to evaluate the high or low value for a sensor
int sampleDelay = 50; // ms to delay between sample readings
int sensingDelay = 100; // ms to delay between readings to determine pour color. Used to handle macro jitter
int delayBetweenPours = 2000; /// ms to delay after sensing a color before it can be sensed again

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

float ranges[numPins] = {0,0,0};
float thresholds[numPins] = {0,0,0};

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
  delay(3000);
  
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
//    Serial.println("Loaded calibrated values.");
  } else {
//    Serial.println("Error: could not find calibration values. Re-run calibration");
  }
  
  // Make sure that all calibration values were recorded properly
//  Serial.println("CALIBRATION VALUES");
//  Serial.println("\t0\t1\t2");
  // TODO It would be nice to have an array of pointers to the color to make this less verbose
  //float *colors[5] = { &lows, &whites, &reds, &yellows, &blues };
  // The post calibration output should look something like this:
  //               0     1     2
  //    LOW      412   532   800
  //    WHITE    412   532   800
  //    RED      412   532   800
  //    YELLOW   412   532   800
  //    BLUE     412   532   800
  
//  Serial.print("LOW\t");
  for (int i = 0; i < numPins; i++) {
//    Serial.print(lows[i]);
//    Serial.print("\t");
  }
//  Serial.println();
  
//  Serial.print("WHITE\t");
  for (int i = 0; i < numPins; i++) {
//    Serial.print(whites[i]);
//    Serial.print("\t");
  }
//  Serial.println();
  
//  Serial.print("RED\t");
  for (int i = 0; i < numPins; i++) {
//    Serial.print(reds[i]);
//    Serial.print("\t");
  }
//  Serial.println();

//  Serial.print("YELLOW\t");
  for (int i = 0; i < numPins; i++) {
//    Serial.print(yellows[i]);
//    Serial.print("\t");
  }
//  Serial.println();

//  Serial.print("BLUE\t");
  for (int i = 0; i < numPins; i++) {
//    Serial.print(blues[i]);
//    Serial.print("\t");
  }
//  Serial.println();

  // Set threshold and range values
  for (int i = 0; i < numPins; i++) {
    ranges[i] = abs(whites[i] - lows[i]);
    thresholds[i] = abs(whites[i] - lows[i]) * thresholdScale;
  }

//  Serial.println("Press button to take readings...");
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

char matchColor(float *readings) {
// This checking approach relies heavily on the values given by the calibration. It is fragile and could be improved by using proportional values instead of the absolute calibration values.

  // Check for white
  boolean isWhite = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in whites, then it's white
  for (int i = 0; i < numPins; i++) {
    if (!(readings[i] - thresholds[i] < whites[i] && readings[i] + thresholds[i] > whites[i])) {
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
    if (!(readings[i] - thresholds[i] < reds[i] && readings[i] + thresholds[i] > reds[i])) {
      isRed = false;
    }
  }
  if (isRed) {
    return 'r';
  }

  // Check for yellow
  boolean isYellow = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in yellows, then it's red
  for (int i = 0; i < numPins; i++) {
    if (!(readings[i] - thresholds[i] < yellows[i] && readings[i] + thresholds[i] > yellows[i])) {
      isYellow = false;
    }
  }
  if (isYellow) {
    return 'y';
  }
  
//  // Check for blue
//  Serial.println("BLUE");
  boolean isBlue = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in blues, then it's red
  for (int i = 0; i < numPins; i++) {
    if (!(readings[i] - thresholds[i] < blues[i] && readings[i] + thresholds[i] > blues[i])) {
      isBlue = false;
    }
  }
  if (isBlue) {
    return 'b';
  }
  
  // No color detected
  return 'x';
}
