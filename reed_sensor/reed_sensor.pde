/* Reed Switch
 * Changes LED when sensor is tripped */

int reedPin = 2;
int ledPin = 11;
int ledOn = 0;
int magnet;

void setup() {
  pinMode(reedPin, INPUT);
  pinMode(ledPin, OUTPUT);
  // Serial.begin(9600);
}

void loop () {
  magnet = digitalRead(pin);

  // Really we want to do this if the magnet has just
  // changed from 1 to 0, not if it is continually 1
  if (magnet == 1) {
    if (ledOn == 0) {
      ledOn = 1;
      digitalWrite(led, HIGH);
    } else {
      ledOn = 0;
      digitalWrite(led, LOW);
    }
  }
//  Serial.println(magnet);
}
