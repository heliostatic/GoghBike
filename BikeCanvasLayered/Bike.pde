/*
 * Bike Class
 * Gogh Bike by Ben Cohen, Ryan Greenberg, Joyce Tsai
 */

class Bike {
  float x, y; // Position coordinates
  float prevX, prevY; // Previous position

  int speed;  // The magnitude of the bike's velocity vector (pixels per second)
  float angle;  // The direction of the bike's velocity vector (degrees in Cartesian space)
  // Ranges from 0 (movement along positive x-axis) to 359
  // Note that Processing places the origin (0,0) in the upper-left corner
  // instead of the lower-left corner, and inverts the y-axis, which leads to
  // counterintuitive display of some angular values

  float direction; // The direction of the handle bars
  // I'm not sure what the proper units are for this
  // given that the handlebars move in a limited fashion
  // from left to right.
  //
  // I suggest that we have the default handlebar position
  // be zero, with positive or negative values indicating 
  // left or right

  double distance; // Total distance traveled in pixels
  ArrayList rpms; // Rotational readings from Arduino
  
  // Painting equipment aboard bike
  PaintCan can;
  int brushWidth; // Width of the paint brush used by the bike
  boolean brushDown; // True if brush is painting
  double nextPaintUsage; // The next distance at which paint will be consumed
  
  // Bike can also be used to play back previous recorded actions
  boolean playback = false;
  boolean playbackComplete = false;

  Bike(int x, int y) {
    // Start position
    this.x = x;
    this.y = y;

    this.speed = 0;
    this.angle = 0;
    this.direction = 0; 
    this.distance = 0;

    this.rpms = new ArrayList();
    for (int i = 0; i < RPM_WINDOW; i++) {
      this.rpms.add(0);
    }
    
    this.can = new PaintCan();
    this.brushWidth = 1;
    this.brushDown = true;
    this.nextPaintUsage = PAINT_USAGE_DISTANCE;
  }

  // Handles all bicycle actions for a frame
  void frame() {
    this.updatePosition();
    this.draw();
    this.wrapCoordinates();
    if (this.brushDown) {
      // Only consume paint if the brush is down
      // TODO This should be refactored so that there is a separate distance and paintDistance
      this.addDistance();
      this.usePaint();     // Consume paint used to draw line
    }
  }

  void updatePosition() {
    // Use current direction to change angle
    this.updateAngle();
    
    // Move current position to past position before calculating new position
    this.prevX = this.x;
    this.prevY = this.y;
    
    // Calculate new position based on speed and direction
    // Determine x and y components of direction based on angle
    // TODO: Animate the distance divided by the frame rate.
    // Note: This is now implemented, but I'm not sure if it is an improvement.
    // Previously: * this.speed, now * ((float) this.speed / FPS)
    this.x = this.x + cos(degToRad(this.angle)) * ((float) this.speed / FPS);
    this.y = this.y + sin(degToRad(this.angle)) * ((float) this.speed / FPS);
    
    // If the new position is off the screen and wrapping is disabled, limit the position
    if (!WRAP_CANVAS) {
        if (this.x < 0) {
            this.x = 0;
        } else if (this.x > CANVAS_WIDTH) {
            this.x = CANVAS_WIDTH;
        }

        if (this.y < 0) {
            this.y = 0;
        } else if (this.y > CANVAS_HEIGHT) {
            this.y = CANVAS_HEIGHT;
        }
    }
  }

  void draw() {
    // Don't draw anything if the bike is stopped or the paint brush is not on the canvas
    // But ignore this if bike is in playback mode, where the speed is not set
    if (this.speed == 0 || !this.brushDown) {
      //println("Returning...bike speed is " + this.speed + " and !brushdown is " + !this.brushDown);
      return;
    }

    // Set the pen color based on paint can
    int[] colors = this.can.getColor();
    canvas.stroke(colors[0], colors[1], colors[2], colors[3]);

    // Draw line
    canvas.line(this.prevX, this.prevY, this.x, this.y);

    // If the point to be drawn is outside the canvas bound,
    // wrap around and draw the second part of the line
    // The first line is drawn from (this.x, this.y) to (x2, y2)
    // The second line is drawn from (x3, y3) to (x4, y4)

    // The first part of the line is drawn between (x1,y1) and (x2,y2)
    // Since the line wraps around the canvas, another line is drawn
    // between (x3,y3) and (x4,y4). The angle and length of the two lines
    // is equal, although the visible portions of each may differ.
    //     
    //                 o (x3,y3)
    //     +---------------+
    //     |     (x4,y4) o |
    //     |               |
    //     |               |
    //     |               |
    //     |               |
    //     |   (x1,y1) o   |
    //     +---------------+
    //                   o  (x2,y2)

    if (this.isOutsideCanvas(this.x, this.y) && WRAP_CANVAS) {
      // Start with the existing pair of points
      float x3 = this.prevX;
      float x4 = this.x;
      float y3 = this.prevY;
      float y4 = this.y;

      // If x is off canvas, calculate wrapped around points to draw line
      if (this.x < 0 || this.x > CANVAS_WIDTH) {
        x4 = (this.x + CANVAS_WIDTH) % CANVAS_WIDTH;
        x3 = (x4 + (this.prevX - this.x));
      }
      // If y is off canvas, calculate wrapped around points to draw line
      if (this.y < 0 || this.y > CANVAS_HEIGHT) {
        y4 = (this.y + CANVAS_HEIGHT) % CANVAS_HEIGHT;
        y3 = y4 + (this.prevY - this.y);
      }

      // Draw second part of line
      canvas.line(x3, y3, x4, y4);
    }

    // Debugging output
    // println("Line from (" + this.prevX + "," + this.prevY + ") to (" + this.x + "," + this.y + ")");
  }

  // Change the absolute direction of the bike
  void updateAngle() {
    // TODO: Maybe change should in angle should occur per unit time
    // This would mean using (this.angle + this.direction / FPS) instead
    // Note: This is what is done now, as seen below. Previously 
    // this.angle = (this.angle + this.direction) % 360;
    // was used
    this.angle = (this.angle + this.direction / FPS) % 360;
  }

  // TODO: This code is copied from draw() and should be refactored
  void wrapCoordinates() {
  if (this.isOutsideCanvas(this.x, this.y) && WRAP_CANVAS) {
      // Start with the existing pair of points
      float x3 = this.prevX;
      float x4 = this.x;
      float y3 = this.prevY;
      float y4 = this.y;

      // If x is off canvas, calculate wrapped around points to draw line
      if (this.x < 0 || this.x > CANVAS_WIDTH) {
        x4 = (this.x + CANVAS_WIDTH) % CANVAS_WIDTH;
        x3 = (x4 + (this.prevX - this.x));
      }
      // If y is off canvas, calculate wrapped around points to draw line
      if (this.y < 0 || this.y > CANVAS_HEIGHT) {
        y4 = (this.y + CANVAS_HEIGHT) % CANVAS_HEIGHT;
        y3 = y4 + (this.prevY - this.y);
      }

      // Copy the values of x4 and y4 to x2 and y2 so they are used to update
      // the bike's position
      this.x = x3;
      this.y = y3;
    }
  }

  // Calculate distance traveled and add to total bike distance
  // The distance traveled is used to calculate paint usage
  void addDistance() {
    this.distance += sqrt(pow((this.x - this.prevX), 2) + pow((this.y - this.prevY),2));
  }

  // Change direction of the bike
  void steerRight(int a) {
    this.steer(a);
  }

  void steerLeft(int a) {
    this.steer(0 - a);
  }

  void steer(int a) {
    if (CORRECT_ANGLE_CHANGE) {
      this.direction += a;
    }
    else {
      this.angle += a;
    }
  }

  // Change the speed of the bicycle
  void speedUp(int s) {
    this.setSpeed(this.speed + s);
  }

  void slowDown(int s) {
    this.setSpeed(this.speed - s);
  }


  // Returns true if the specified coordinates are off the canvas
  boolean isOutsideCanvas(float x, float y) {
    if (x > CANVAS_WIDTH || x < 0) {
      return true;
    } 
    else if (y > CANVAS_HEIGHT || y < 0) {
      return true;
    } 
    else {
      return false;
    }
  }


  // Use a set of readings for the bike's RPMs to calculate the current speed.
  //
  // We average the RPM readings for more consistent speed readings, especially
  // at low speeds. If someone is pedaling slowly, the readings will be something
  // like 0,1,0,0,1,0,0,1. We don't want to go for half a second and then stop
  // for another two readings. Instead we want to set the speed to about 1/3.
  //
  // Note: technically these are rotation per second readings, not per minute.
  //
  // TODO: We should add some better detection to see if the bike is stopping
  void setSpeedFromRpms() {
    if (this.playback == true) {
      println("Not setting speed");
      return;
    }
    float speed = 0;
    for (int i = 0; i < this.rpms.size(); i++) {
      // TODO: Ben says this is the worst possible way to do this
      // I don't know if there is a better way to cast an object to a float
      speed += float(this.rpms.get(i).toString());
    }
    speed = speed / this.rpms.size();
    // println("Current average speed is " + speed);
    this.setSpeed((int) ((speed / 6) * 300));
  }


  /**
   * Translates movement from potentiometer to changes in the direction of bicycle
   *
   * TODO: This might have a non-linear mapping so that there is a "sweet spot" to center
   * the steering and so far values have an exaggerated turn
   */
  void setDirectionFromPotentiometer(float reading) {
    int direction = (int) ((reading - READING_LOWER_BOUND) / (READING_UPPER_BOUND - READING_LOWER_BOUND) * (DIRECTION_UPPER_BOUND - DIRECTION_LOWER_BOUND)) + DIRECTION_LOWER_BOUND;
    // println("After setDirectionFromPotentiometer direction = " + direction);
    if (direction < DIRECTION_LOWER_BOUND) {
      direction = DIRECTION_LOWER_BOUND;
    } else if (direction > DIRECTION_UPPER_BOUND) {
      direction = DIRECTION_UPPER_BOUND;
    }
    this.setDirection((float) direction);
  }
  
  /**
   * Overloaded method to handle String arguments
   */
  void setDirectionFromPotentiometer(String reading) {
    if (this.playback) {
      return;
    }
    this.setDirectionFromPotentiometer(float(reading));
  }

  /**
   * Consume paint from associated paint can and set next distance at which paint should be consumed.
   */
  void usePaint() {
    if (this.distance > this.nextPaintUsage) {
      this.can.usePaint();
      this.nextPaintUsage = this.distance + PAINT_USAGE_DISTANCE;

      // String volume = this.can.getVolumesString(); // DEBUG
      // println("Used paint. Currently at " + this.can.getVolume() + " units of paint. " + volume); // DEBUG
      // println("Bike has traveled " + this.distance + " pixels.");
    }
  }

  // Getters and Setters
  void setDirection(float d) {
    // println("Setting bicycle direction to " + d);
    this.direction = d;
  }

  float getDirection() {
    return this.direction;
  }

  void setSpeed(int s) {
    this.speed = s > 0 ? s : 0;
    // println("Setting speed to " + this.speed);
  }

  int getSpeed() {
    return this.speed;
  }

  void setAngle(float a) {
    this.angle = a % 360;
  }

  float getAngle() {
    return this.angle;
  }
  
  void setBrushWidth(int w) {
    this.brushWidth = w > 0 ? w : 1;
    canvas.strokeWeight(this.brushWidth);
  }
  
  int getBrushWidth() {
    return this.brushWidth;
  }

  void setBrushDown(int b) {
    if (this.playback) {
      return;
    }
    if (b == 1) {
      this.brushDown = false;
    } else {
      this.brushDown = true;
    }
  }

  void setBrushDown() {
    this.brushDown = true;
  }
  
  void setBrushUp() {
    this.brushDown = false;
  }
  
  void toggleBrushDown() {
    this.brushDown = !this.brushDown;
  }

  // VERSION 1.0:
  // x  y  red  yellow  blue  white
  // VERSION 1.1:
  // x  y  brushDown  red  yellow  blue  white
  String state() {
    return String.format("%f\t%f\t%d\t%s", this.x, this.y, int(this.brushDown), this.can.state());
  }
  
  void loadState(String s) {
    String[] pieces = split(s, TAB);
    if (pieces.length != 7) {
      println("State to load is malformed. Check recording for truncated lines.");
    } else {
      this.prevX = this.x;
      this.prevY = this.y;
      this.x = float(pieces[0]);
      this.y = float(pieces[1]);
      this.brushDown = boolean(int(pieces[2]));
      
      this.can.r = float(pieces[3]);
      this.can.y = float(pieces[4]);
      this.can.b = float(pieces[5]);
      this.can.w = float(pieces[6]);
    }
  }
}

// Convert degrees to radians
float degToRad(float d) {
  return (d % 360) / 360 * TWO_PI;
}

