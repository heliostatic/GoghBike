/*
 * Gogh Bike Canvas (Layered)
 * Gogh Bike by Ben Cohen, Ryan Greenberg, Joyce Tsai
 */
 
import processing.serial.*;
import ddf.minim.*;

// The current layer implementation is very slow because of the slow JAVA 2D library.
// An alternative might be to use GLGraphics
// See http://users.design.ucla.edu/~acolubri/processing/glgraphics/home/index.html
// import processing.opengl.*;

// Sound effects
Minim minim;
String SOUND_FX_PATH_1 = "pour1.mp3";
String SOUND_FX_PATH_2 = "pour2.mp3";
String SOUND_FX_PATH_3 = "pour3.mp3";
String SOUND_FX_PATH_4 = "pour4.mp3";
AudioSample pourSoundFx1;
AudioSample pourSoundFx2;
AudioSample pourSoundFx3;
AudioSample pourSoundFx4;

boolean DEBUG = false;

// Screen size, constants, and buffers
final static int SCREEN_WIDTH = 1024;
final static int SCREEN_HEIGHT = 768;
final static int CANVAS_WIDTH = 768;
final static int CANVAS_HEIGHT = 768;
final static int FPS = 30; // For whatever reason, not accurate
final static boolean WRAP_CANVAS = false; // Whether the brush stops or moves to the other side of the canvas
static boolean ROTATE_CANVAS = true; // Whether the canvas is rotated with the change in the brush angle
PGraphics canvas, overlay;

float drawInterval; // milliseconds between canvas updates

// Bike variables
final static int RPM_WINDOW = 3;

// Expected range of values from potentiometer
final static int READING_CENTER = 199;
final static int READING_UPPER_BOUND = 85;
final static int READING_LOWER_BOUND = 340;

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
final static int PAINT_BRUSH_WIDTH = 5; // Width of brush used on canvas
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

// Simulation objects
Bike bike = new Bike(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2); // Initially place the bike in the center of the canvas
Recorder recorder;
Player player;
final static String FILE_PATH = "recordings/"; // Path to save bike recordings
final static boolean RECORDING_ENABLED = false;

long i = 0;
float actualFrames = 0;
long startActualFrames = 0;

void setup() {
  // Create canvas and graphics buffers
  size(SCREEN_WIDTH, SCREEN_HEIGHT);
  background(0);
  smooth();
  canvas = createGraphics(CANVAS_WIDTH, CANVAS_HEIGHT, JAVA2D); // Background layer where bike paints
  overlay = createGraphics(CANVAS_WIDTH, CANVAS_HEIGHT, P3D); // Overlay layer with indicators
  canvas.beginDraw();
  canvas.background(255);
  canvas.smooth();
  canvas.endDraw();

  // Calculate interval between draws based on specified frames per second
  // This could be done using the frameRate() option, but I think this offers
  // more precise control over timing.
  drawInterval = (1.0 / FPS) * 1000.0;
  println("For " + FPS + " frames per second, each frame displayed for " + drawInterval + "ms");
  startActualFrames = millis();

  // For testing set fixed bike speed
  bike.setSpeed(0);
  bike.setAngle(270);
  bike.setBrushWidth(PAINT_BRUSH_WIDTH);

  recorder = new Recorder(FILE_PATH, bike);

  // Load sound effects
  minim = new Minim(this);
  pourSoundFx1 = minim.loadSample(SOUND_FX_PATH_1, 2048);
  pourSoundFx2 = minim.loadSample(SOUND_FX_PATH_2, 2048);
  pourSoundFx3 = minim.loadSample(SOUND_FX_PATH_3, 2048);
  pourSoundFx4 = minim.loadSample(SOUND_FX_PATH_4, 2048);

  // Connect to Arduino boards
  println("Connecting to serial devices...");
  println(Serial.list());

  paintPort = new Serial(this, paintPortname, 115200);
  bikePort = new Serial(this, bikePortname, 9600);
  lightPort = new Serial(this, lightPortname, 9600);

  bikePort.bufferUntil(lf);
  paintPort.bufferUntil(lf);
  lightPort.bufferUntil(lf);

  frameRate(FPS);
}

void draw() {
    actualFrames++;
    background(0);
    canvas.beginDraw();
    
  if (bike.playback) {
    // For each call of advance(), use this.playbackSpeed
    //  to determine how many frames to draw
    for (int i = 0; i < player.playbackSpeed; i++) {    
      player.advance();
      bike.draw();
    }
  } else {
    bike.frame();
    recorder.write();
  }
    canvas.endDraw();
    
  if (ROTATE_CANVAS && !bike.playback) {
      // We translate the screen to put 0,0 at the center of the screen
      // Then we rotate the canvas and place the canvas image on the screen so that the brush position remains constant
      translate(SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
      rotate(radians(270 - bike.angle));
      image(canvas, (0 - (CANVAS_WIDTH / 2)) + ((CANVAS_WIDTH / 2) - bike.x), (0 - (CANVAS_HEIGHT / 2)) + ((CANVAS_WIDTH / 2) - bike.y));
  } else {
      image(canvas, int((SCREEN_WIDTH - CANVAS_WIDTH)/2), 0);
  }

  // Framerate for debugging
//  i++;
//  if (i % 100 == 0) {
//    println(frameRate);
//    println("Actual frame rate: " + ((actualFrames / (millis() - startActualFrames)) * 1000));
//    startActualFrames = millis();
//    actualFrames = 0;
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
    resetBike();
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
  else if (key == 'z') {
    toggleRotatingCanvas();
  }
  else if (key == 'c') {
    println("Closing recording...NOT IMPLEMENTED");
    //    closeRecording();
  }
  else if (key == 's') {
    println("Sending serial event...");
    serialEvent(paintPort);
  }
  else if (key == 'o') {
    openRecording();
  } else if (key == '-') {
    if (player != null) {
      player.decreasePlaybackSpeed();
    }
  } else if (key == '=' || key == '+') {
    if (player != null) {
      player.increasePlaybackSpeed();
    }
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
        } 
        else if (stringBuf.charAt(0) == 'b') {
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

void toggleRotatingCanvas() {
  ROTATE_CANVAS = !ROTATE_CANVAS;
}

void openRecording() {
  String loadPath = selectInput();  // Opens file chooser
  if (loadPath == null) {
    // If a file was not selected
    println("No file was selected...");
  } 
  else {
    // If a file was selected, reset the canvas and play the file
    resetCanvas();
    // Close the recorder for the current bike if it exists
    if (!recorder.equals(null)) {
      println("Closing existing recorder...");
      recorder.close();
    }
    bike = new Bike(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2);
    player = new Player(loadPath, bike);
  }
}

void resetCanvas() {
  background(255);
  canvas.beginDraw();
  canvas.background(255);
  canvas.endDraw();
}

void resetBike() {
  // Close the recorder for the current bike if it exists
  if (!recorder.equals(null)) {
    println("Closing existing recorder...");
    recorder.close();
  } else {
    println("No recorder to close...");
  }

  // Create a new bike and recorder
  bike = new Bike(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2); // Initially place the bike in the center of the canvas
  bike.setSpeed(0);
  bike.setAngle(270);
  bike.setBrushWidth(5);
  recorder = new Recorder(FILE_PATH, bike);
}

void stop() {
  // Close sound effects
  pourSoundFx1.close();
  pourSoundFx2.close();
  pourSoundFx3.close();
  pourSoundFx4.close();
  minim.stop();
  recorder.close();
  super.stop();
}
