/* 
 * Color Light Calibration
 * Ryan Greenberg
 * 24 November 2009
 *
 * Connect a photosensor to analog inputs 0, 1, and 2 and a button to digital pin 2.
 */

int buttonPin = 2; // Button used to help with calibration
int redPin = 1;
int yellowPin = 2;
int bluePin = 0;
char color;

int photoPins[] = {0, 1, 2}; // Arduino pins that photosensors are connected to
const int numPins = sizeof(photoPins) / sizeof(int); // Number of photosensors connected to Arduino
const int sampleWindow = 10; // Number of readings to use to evaluate the high or low value for a sensor
int sampleDelay = 50; // ms to delay between sample readings
int sensingDelay = 500; // ms to delay between readings to determine pour color. Used to handle macro jitter

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
  Serial.println("loading");

  pinMode(buttonPin, INPUT);

  // Do an interactive calibration to set photosensor values for different light levels

  // LOW/AMBIENT LIGHT
  // Set low light value for sensor
  Serial.println("Recording low/ambient light values...");
  samplePhotoSensors(sampleVals);
//  Serial.println("low sampleVals:");
//  for (int i = 0; i < sizeof(sampleVals) / sizeof(int); i++) {
//    Serial.println(sampleVals[i]);
//  }
  
  photoSensorAverages(lows, sampleVals);
  
  Serial.println("Average low values...");
  for (int i = 0; i < numPins; i++) {
    Serial.print(i);
    Serial.print(": ");
    Serial.println(lows[i]);
  }
  
  // WHITE LIGHT
  // Set white light value for sensor
  Serial.println("Press button to set white light values..."); 
  waitForButtonPress();
  Serial.println("Recording white light values...");
  samplePhotoSensors(sampleVals);
  photoSensorAverages(whites, sampleVals);
  
  // RED LIGHT
  // Set red light value for sensor
  Serial.println("Press button to set red light values..."); 
  waitForButtonPress();
  Serial.println("Recording red light values...");
  samplePhotoSensors(sampleVals);
  photoSensorAverages(reds, sampleVals);
  
  // YELLOW LIGHT
  // Set yellow light value for sensor
  Serial.println("Press button to set yellow light values..."); 
  waitForButtonPress();
  Serial.println("Recording yellow light values...");
  samplePhotoSensors(sampleVals);
  photoSensorAverages(yellows, sampleVals);
  
  // BLUE LIGHT
  // Set blue light value for sensor
  Serial.println("Press button to set blue light values..."); 
  waitForButtonPress();
  Serial.println("Recording blue light values...");
  samplePhotoSensors(sampleVals);
  photoSensorAverages(blues, sampleVals);

  // Make sure that all calibration values were recorded properly
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

  // Set threshold and range values
  for (int i = 0; i < numPins; i++) {
    ranges[i] = abs(whites[i] - lows[i]);
    thresholds[i] = abs(whites[i] - lows[i]) * thresholdScale;
  }

  Serial.println("Press button to take readings...");
  Serial.println("ready");
}


void loop() {
  // Version 1 for gathering sample data
//  waitForButtonPress();
//  samplePhotoSensors(sampleVals);
//  photoSensorAverages(current, sampleVals);
//  // For debugging print all sensors' current values
//  Serial.print("\t");
//  for (int i = 0; i < numPins; i++) {
//    Serial.print(current[i]);
//    Serial.print("\t");
//  }
//  Serial.println();
  
  // Version 2 for testing
  sampleDelay = 0;
  samplePhotoSensors(sampleVals);
  photoSensorAverages(current, sampleVals);
  color = matchColor(current);
  if (color == 'X') {
    // No color detected
    Serial.println("No color detected");
  } else {
    // Color detected
    Serial.print("Color detected: ");
    Serial.println(color);
    delay(sensingDelay);
    samplePhotoSensors(sampleVals);
    photoSensorAverages(current, sampleVals);
    if (color == matchColor(current)) {
      // Confirmed color match
      Serial.print("C");
      Serial.println(color);
    } else {
      Serial.println("Colors did not match");
      Serial.print("Second color was ");
      Serial.print(matchColor(current));
    }
  }
//  delay(100);
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
// This checking approach relies heavily on the values given by the calibration. It is fragile and does not detect the
// right color with any frequency.

  // Check for white
  boolean isWhite = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in whites, then it's white
  for (int i = 0; i < numPins; i++) {
    if (!(readings[i] - thresholds[i] < whites[i] && readings[i] + thresholds[i] > whites[i])) {
      isWhite = false;
    }
  }
  if (isWhite) {
    return 'W';
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
    return 'R';
  }

  // Check for yellow
  boolean isYellow = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in reds, then it's red
  for (int i = 0; i < numPins; i++) {
    if (!(readings[i] - thresholds[i] < yellows[i] && readings[i] + thresholds[i] > yellows[i])) {
      isYellow = false;
    }
  }
  if (isYellow) {
    return 'Y';
  }
  
//  // Check for blue
//  Serial.println("BLUE");
  boolean isBlue = true;
  // Look at the value for each pin in readings if they are within x% of the value for that pin in reds, then it's red
  for (int i = 0; i < numPins; i++) {
    if (!(readings[i] - thresholds[i] < blues[i] && readings[i] + thresholds[i] > blues[i])) {
      isBlue = false;
    }
  }
  if (isBlue) {
    return 'B';
  }
  
  // No color detected
  return 'X';

// This approach relies on knowing which pin is which color, which requires some additional constants in code
// Currently hard-coded here with pin 0 = blue, pin 1 = red, pin 2 = yellow
//
//  float redPercent = (readings[redPin] - lows[redPin]) / ranges[redPin];
//  float yellowPercent = (readings[yellowPin] - lows[yellowPin]) / ranges[yellowPin];
//  float bluePercent = (readings[bluePin] - lows[bluePin]) / ranges[bluePin];
//
//  // Check for red
//  if (redPercent > bluePercent && redPercent > yellowPercent) {
//    Serial.println("RED");
//  }
//
//  // Check for yellow
//  if (yellowPercent > redPercent && yellowPercent > bluePercent) {
//    Serial.println("YELLOW");
//  }
//  
//  // Check for blue
//  if (bluePercent > redPercent && bluePercent > yellowPercent) {
//    Serial.println("BLUE");
//  }
}


// Loops until button is pressed
void waitForButtonPress() {
  while(digitalRead(buttonPin) == HIGH) {
  }
}
