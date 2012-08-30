/*
 * Color Light Calibration
 * Ryan Greenberg
 * 24 November 2009
 *
 * On setup() this program sets threshold values independently for each
 * connected photosensors. When this threshold value is crossed, letters
 * that correspond to each sensors are sent via the serial connection for
 * processing.
 *
 * Connect a photosensor to analog inputs 0, 1, 2, 3, and 4.
 */

// Button used to help with calibration
int buttonPin = 2;

const int numPins = 2;
const int sampleWindow = 10; // Number of readings to use to evaluate the high or low value for a sensor
const int sampleDelay = 100; // ms to delay between sample readings
int photoPins[numPins] = {
  0, 1};

int vals[numPins] = {
  0,0};
int photoStates[numPins] = {
  0,0}; // Current HIGH (1) or LOW (0) state for a given photosensor
int window[numPins * sampleWindow];
int windowSum[numPins];

float lows[numPins] = {
  0,0}; // Threshold values that determine HIGH or LOW for each sensor
float highs[numPins] = {
  0,0}; // Threshold values that determine HIGH or LOW for each sensor
float thresholds[numPins] = {
  0,0}; // Threshold values that determine HIGH or LOW for each sensor

// Direction to scale the initial reading when creating a threshold. If the initial
// reading is taken in a LOW state (no light), this should be 1, indicating that the
// threshold is created in a positive direciton. If the initial reading is in a HIGH
// state (light activated), this should be -1, indicating that the threshold is created
// in a negative direction.
float thresholdScale = .10; // pecentage to use when scaling initial reading to set threshold level
float thresholdScaleSmall = .20; // scaling percentage for sensors with very low initial values
int thresholdDirection = -1;

// TODO It might be useful to use map for reading test values
// http://arduino.cc/en/Reference/Map

void setup() {
  Serial.begin(9600);
  Serial.println("loading");

  pinMode(buttonPin, INPUT);

  // Set initial threshold for each photosensor

  Serial.println("Recording low/ambient light values...");
  // Set low value for sensor
  // Use sample window to average values over period of time
  for (int n = 0; n < sampleWindow * numPins;) {
    for (int i = 0; i < numPins; i++) {
      window[n] = analogRead(photoPins[i]);
      n++;
    }
    Serial.print("Reading #");
    Serial.println(n / 2 + 1);
    delay(sampleDelay);
  }

  // Average low readings
  for (int i = 0; i < numPins; i++) {
    windowSum[i] = 0;
    Serial.print("window readings for pin ");
    Serial.println(i);
    for (int j = 0; j < sizeof(window) / sizeof(int); j++) {
      if (j % numPins == i) {
        Serial.println(window[j]);
        windowSum[i] += window[j];
      }
    }
    //lows[i] = analogRead(photoPins[i]);
    lows[i] = (int) windowSum[i] / sampleWindow;
    Serial.print("Pin ");
    Serial.print(i);
    Serial.print(" low: ");
    Serial.println(lows[i]);
  }

  // Wait for button to set highs
  Serial.println("Press button to set high light values..."); 
  while(digitalRead(buttonPin) == HIGH) {
  }

  Serial.println("Recording high light values...");
  // Set high value for sensor
  // Use sample window to average values over period of time
  for (int n = 0; n < sampleWindow * numPins;) {
    for (int i = 0; i < numPins; i++) {
      window[n] = analogRead(photoPins[i]);
      n++;
    }
    Serial.print("Reading #");
    Serial.println(n / 2 + 1);
    delay(sampleDelay);
  }

  // Average high readings
  for (int i = 0; i < numPins; i++) {
    windowSum[i] = 0;
    Serial.print("window readings for pin ");
    Serial.println(i);
    for (int j = 0; j < sizeof(window) / sizeof(int); j++) {
      if (j % numPins == i) {
        Serial.println(window[j]);
        windowSum[i] += window[j];
      }
    }
    highs[i] = (int) windowSum[i] / sampleWindow;
    Serial.print("Pin ");
    Serial.print(i);
    Serial.print(" high: ");
    Serial.println(highs[i]);
  }

  // Set threshold valuies 
  for (int i = 0; i < numPins; i++) {
    thresholds[i] = lows[i] + ((highs[i] - lows[i]) / 2);
    Serial.print("Pin ");
    Serial.print(i);
    Serial.print(" threshold: ");
    Serial.println(thresholds[i]);
  }

  Serial.println("ready");
  
}

void loop() {
  // Read value of photosensors
  for (int i = 0; i < numPins; i++) {
    Serial.print("i: ");
    Serial.print(i);
    Serial.print(": ");
    vals[i] = analogRead(photoPins[i]);
    if (vals[i] > thresholds[i] && photoStates[i] == 0) {
      // Crossed threshold to HIGH state
      //      Serial.print("Pin ");
      //      Serial.print(i);
      //      Serial.println(" HIGH");
      //      Serial.println(vals[i]);
      photoStates[i] = 1;
    } 
    else if (vals[i] < thresholds[i] && photoStates[i] == 1) {
      // Crossed threshold to LOW state
      //            Serial.print("Pin ");
      //            Serial.print(i);
      //            Serial.println(" LOW");
      //      Serial.println(vals[i]);
      photoStates[i] = 0;
    }
    Serial.println(vals[i]);
  }

  delay(1000);
}

