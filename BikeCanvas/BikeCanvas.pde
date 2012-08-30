/*
 * Gogh Bike Canvas
 * Gogh Bike by Ben Cohen, Ryan Greenberg, Joyce Tsai
 */

import processing.serial.*;
import ddf.minim.*;

// Sound effects
Minim minim;
String SOUND_FX_PATH = "pour1.mp3";
AudioSample pourSoundFx;

boolean DEBUG = false;

// Screen size and constants
final static int CANVAS_WIDTH = 400;
final static int CANVAS_HEIGHT = 400;
final static int FPS = 30;
final static boolean WRAP_CANVAS = false;

float drawInterval; // milliseconds between canvas updates
double nextDraw; // time of next scheduled draw

// Bike variables
final static int RPM_WINDOW = 3;

// Expected range of values from potentiometer
final static int READING_CENTER = 321;
final static int READING_UPPER_BOUND = 105;
final static int READING_LOWER_BOUND = 480;

// Defined range for steering bicycle
final static int DIRECTION_LOWER_BOUND = -150;
final static int DIRECTION_CENTER = 0;
final static int DIRECTION_UPPER_BOUND = 150;
final static boolean CORRECT_ANGLE_CHANGE = false; // Change this to true when using an actual bicycle

// Paint variables
final static int VOLUME_OF_CAN = 100; // Maximum volume of paint can in units of paint
final static int VOLUME_PER_POUR = 10; // Units of paint added to bucket when a color is poured in
final static int VOLUME_PER_USAGE = 1; // Units of paint used when bike travels PAINT_USAGE_DISTANCE
final static int PAINT_USAGE_DISTANCE = 50; // Distance in pixels that bike must travel to use VOLUME_PER_USAGE paint
final static int PAINT_OPACITY_THRESHOLD = 10; // Volume of can at which brush begins to become transparent
boolean fakePaintMode = false;
boolean serialPaintEnabled = true;

// Serial communication
boolean bikeSerialReady = false;
String bikePortname = "/dev/tty.usbserial-A7006RZH"; // or "COM5"
Serial bikePort;
boolean paintSerialReady = false;
String paintPortname = "/dev/tty.usbserial-A7006TaC"; // or "COM5"
Serial paintPort;
boolean lightSerialReady = false;
String lightPortname = "/dev/tty.usbserial-A7006SoU"; // or "COM5"
Serial lightPort;
String buf="";
String stringBuf="";
String bikeBuf="";
String paintBuf="";
int cr = 13;  // ASCII return   == 13
int lf = 10;  // ASCII linefeed == 10

Bike bike = new Bike(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2); // Initially place the bike in the center of the canvas

long i = 0;

void setup() {

  // Create canvas and graphics buffers
  size(CANVAS_WIDTH, CANVAS_HEIGHT);
  background(255);
  smooth();

  // Calculate interval between draws based on specified frames per second
  // This could be done using the frameRate() option, but I think this offers
  // more precise control over timing.
  drawInterval = (1.0 / FPS) * 1000.0;
  println("For " + FPS + " frames per second, each frame displayed for " + drawInterval + "ms");
  nextDraw = millis();

  // For testing set fixed bike speed
  bike.setSpeed(0);
  bike.setAngle(270);
  bike.setBrushWidth(5);

  // Load sound effects
  minim = new Minim(this);
  pourSoundFx = minim.loadSample(SOUND_FX_PATH, 2048); // Sound effect sample

  // Connect to Arduino boards
  println("Connecting to serial devices...");
  println(Serial.list());

  paintPort = new Serial(this, paintPortname, 115200);
  bikePort = new Serial(this, bikePortname, 9600);
  lightPort = new Serial(this, lightPortname, 9600);

  bikePort.bufferUntil(lf);
  paintPort.bufferUntil(lf);
  lightPort.bufferUntil(lf);
}


void draw() {
  //  if (bikeSerialReady && lightSerialReady) {
  // Check if frame is ready to be drawn
  if (millis() > nextDraw) {
    bike.frame();
    nextDraw = millis() + drawInterval;
  }
  //  } else {
  //    println("Not ready");
  //  }
}


// In debug mode, the up and down arrow keys control the speed.
// Left and right arrows control steering
// r, g, b, and w pour that color of paint into the can
// e empties the can
void keyPressed() {
  // In MacOS X, the key codes for the arrow keys are:
  // 37 left
  // 38 up
  // 39 right
  // 40 down
  switch(keyCode) {
  case 37: // Left arrow
    // println("left");
    bike.steerLeft(5);
    break;
  case 38: // Up arrow
    // println("up");
    bike.speedUp(10);
    break;
  case 39: // Right arrow
    //println("right");
    bike.steerRight(5);
    break;
  case 40: // Down arrow
    // println("down");
    bike.slowDown(10);
    break;
  case 8: // Delete key
    resetCanvas();
    break;
  default:
  }

  // Adding and removing paint
  if (key == 'r') {
    bike.can.addRed();
  } 
  else if (key == 'y') {
    bike.can.addYellow();
  } 
  else if (key == 'b') {
    bike.can.addBlue();
  } 
  else if (key == 'w') {
    bike.can.addWhite();
  }
  else if (key == 'e') {
    bike.can.empty();
  } 
  else if (key == 'q') {
    bike.toggleBrushDown();
  } 
  else if (key == 'f') {
    toggleFakeMode();
  } 
  else if (key == 'd') {
    toggleSerialPaintEnabled();
  }

  // Debugging
  //    println("keyCode: " + keyCode);
  //    println("key: " + key);
}


// Serial communication
void serialEvent(Serial p) {
  if (bikePort.available() > 0) {
    try {
      stringBuf = bikePort.readStringUntil(lf);
      stringBuf = stringBuf.substring(0, stringBuf.length()-2); // Strip CR/LF

      if (bikeSerialReady) {
        if (stringBuf.charAt(0) == 'r') {
          // Rotation
          // Push the current reading and shift the reading at the beginning of the ArrayList
          bike.rpms.add(stringBuf.substring(1));
          bike.rpms.remove(0);
          bike.setSpeedFromRpms();
        } 
        else if (stringBuf.charAt(0) == 's') {
          // Steering
          bike.setDirectionFromPotentiometer(stringBuf.substring(1));
        } else if (stringBuf.charAt(0) == 'b') {
          // Brake
          bike.setBrushDown(int(stringBuf.substring(1)));
        } 
        else {
          println("Received: " + stringBuf);
        }
      }

      if (!bikeSerialReady && stringBuf.equals("ready")) {
        bikeSerialReady = true;
        println("Bicycle serial port ready");
      }
      else if (!bikeSerialReady) {
        // Display any information that is received before ready
        // This is debugging information
        println(stringBuf);
      }    
    } 
    catch (Exception e) {
      println("Caught exception: " + e);
    }
  }

  // Serial data from light sensor
  if (lightPort.available() > 0) {
    try {
      stringBuf = lightPort.readStringUntil(lf);
      stringBuf = stringBuf.substring(0, stringBuf.length()-2); // Strip CR/LF

      if (lightSerialReady) {
        if (serialPaintEnabled) {

          if (fakePaintMode) {
            bike.can.addWhite();
          } 
          else {
            if (stringBuf.equals("cr")) {
              bike.can.addRed();
            } 
            else if (stringBuf.equals("cb")) {
              bike.can.addBlue();
            } 
            else if (stringBuf.equals("cy")) {
              bike.can.addYellow();
            } 
            else if (stringBuf.equals("cw")) {
              bike.can.addWhite();
            } 
            else {
              println("Received: " + stringBuf);
            }
          }
        }
      }

      if (!lightSerialReady && stringBuf.equals("ready")) {
        lightSerialReady = true;
        println("Light sensor serial port ready");
      }
      else if (!lightSerialReady) {
        // Display any information that is received before ready
        // This is debugging information
        println(stringBuf);
      }
    } 
    catch (Exception e) {
      println("Caught exception: " + e);
    }
  }

  if (paintPort.available() > 0) {
    try {
      stringBuf = paintPort.readStringUntil(lf);
      stringBuf = stringBuf.substring(0, stringBuf.length()-2); // Strip CR/LF

      if (paintSerialReady) {
        println("Received: " + stringBuf);
      }

      if (!paintSerialReady && stringBuf.equals("ready")) {
        paintSerialReady = true;
        println("Paint bucket serial port ready");
      } 
      else if (!paintSerialReady) {
        // Display any information that is received before ready
        // This is debugging information
        println(stringBuf);
      }
    } 
    catch (Exception e) {
      println("Caught exception: " + e);
    }
  }
}

void toggleFakeMode() {
  fakePaintMode = !fakePaintMode;
  println("Fake paint mode is " + fakePaintMode);
}

void toggleSerialPaintEnabled() {
  serialPaintEnabled = !serialPaintEnabled;
  println("serialPaintEnabled is " + serialPaintEnabled);
}

void resetCanvas() {
  background(255);
  bike = new Bike(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2); // Initially place the bike in the center of the canvas
  bike.setSpeed(0);
  bike.setAngle(270);
  bike.setBrushWidth(5);
  nextDraw = millis();
}

void stop() {
  // Close sound effects
  pourSoundFx.close();
  minim.stop();
  super.stop();
}


