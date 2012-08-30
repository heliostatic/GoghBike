/* 
 * Bicycle Sensors
 * Bike Gogh by Ben Cohen, Ryan Greenberg, Joyce Tsai
 * 
 * Setup:
 * LED on digital pin 11 (for debugging)
 * Reed switch on digital pin 2 (interrupt 0)
 * Photosensor on digital pin 3 (interrupt 1)
 * Potentiometer on analog 1
 * For debugging also changes LED when reed switch changes.
 */

int ledPin = 11; // LED
int potPin = 1; // Potentiometer
int photoPin = 3; // Photocell (when not using interrupt)

int counter = 0;
boolean brake = false;

long nextSwitchTime = 0;
int resolution = 330; // ms between sending readings via serial

long nextCountTime = 0;
int countResolution = 5;
long nextStopCountTime = 0;
int stopCountResolution = 2; // Used for debouncing

volatile int state = LOW;

void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(photoPin, INPUT);
  attachInterrupt(0, blink, RISING);
  attachInterrupt(1, changeBrake, CHANGE);
  nextSwitchTime = millis() + resolution;
  nextCountTime = millis() + resolution;
  Serial.begin(9600);
  Serial.println("ready");
}

void loop () {
  digitalWrite(ledPin, state);
  if (nextSwitchTime < millis()) {
    // Rotation count
    nextSwitchTime = millis() + resolution;
    Serial.print('r'); // Rotation/rpm
    Serial.println(counter);
    counter = 0;
    
    // Steering potentiometer
    Serial.print('s'); // Steering
    Serial.println(analogRead(potPin)); 
  }
}

void blink() {
  if(nextCountTime < millis()) {
    nextCountTime = millis() + countResolution;
    counter++;
    state = !state;
  }
}

void changeBrake() {
  if(nextStopCountTime < millis()) {
    nextStopCountTime = millis() + stopCountResolution;
    // Serial.println("brake changed");
    if (digitalRead(photoPin) == LOW) {
      // Serial.println("brake OFF");
      Serial.println("b0");
    } else {
      // Serial.println("brake ON");
      Serial.println("b1");
    }
  }
}
