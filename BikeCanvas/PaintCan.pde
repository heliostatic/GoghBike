/*
 * Paint Can
 * Gogh Bike by Ben Cohen, Ryan Greenberg, Joyce Tsai
 */

class PaintCan {
  // Volume of component paint colors
  // This is a unitless measure; the maximum volume is an adjustable constant
  float r;
  float y;
  float b;
  float w;
  
  String serialBucketColor;

  PaintCan() {
    this.r = 0;
    this.y = 0;
    this.b = 0;
    this.w = 0;
    
    this.serialBucketColor = "0,0,0,0,0,0,0,0,0,0,0,0";

    if (DEBUG) {
      this.r = 100;
    }
  }

  // Getters and Setters
  // Number of seconds that red has been added 
  void addRed() {
    this.addColor("red");
  }

  void addBlue() {
    this.addColor("blue");
  }

  void addYellow() {
    this.addColor("yellow");
  }

  void addWhite() {
    this.addColor("white");
  }

  void addColor(String paintColor) {
    // We can't add anything to the paint can if there isn't enough space
    if (this.getVolume() > VOLUME_OF_CAN - VOLUME_PER_POUR) {
      return;
    }
    else {
      pourSoundFx.trigger();
      
      if (paintColor.equals("red")) {
        this.r += VOLUME_PER_POUR;        
      } 
      else if (paintColor.equals("blue")) {
        this.b += VOLUME_PER_POUR;
      } 
      else if (paintColor.equals("yellow")) {
        this.y += VOLUME_PER_POUR;
      } 
      else if (paintColor.equals("white")) {
        this.w += VOLUME_PER_POUR;
      }

      println("Added " + VOLUME_PER_POUR + " units of " + paintColor + " paint to can. Current volume is " + this.getVolume() + " units.");
      this.sendSerialBucketColor();
    }

  }

  // Use a fixed amount of paint from total can
  // This uses a proportional amount of each color to equal the total
  //
  // For example, if there are 20 units of red and 30 units of yellow,
  // using 10 units of paint would use 4 units of red and 6 units of yellow.
  void usePaint() {
    float volume = this.getVolume();
    // There is no paint to use if volume is 0
    if (volume > 0) {

      this.r -= this.r / volume * VOLUME_PER_USAGE;
      this.y -= this.y / volume * VOLUME_PER_USAGE;
      this.b -= this.b / volume * VOLUME_PER_USAGE;
      this.w -= this.w / volume * VOLUME_PER_USAGE;

      // Make sure all volumes are not less than 0
      this.r = this.r < 0 ? 0 : this.r;
      this.y = this.y < 0 ? 0 : this.y;
      this.b = this.b < 0 ? 0 : this.b;
      this.w = this.w < 0 ? 0 : this.w;
    }
    
    this.sendSerialBucketColor();
  }

  void empty() {
    println("Emptying paint can...");
    this.r = 0.0;
    this.y = 0.0;
    this.b = 0.0;
    this.w = 0.0;
    
    this.sendSerialBucketColor();
  }

  /**
   * Convert the current volumes of paint to an RGB color for painting on the canvas
   * When the 
   * Goals:
   *     - When paint is consumed, the color should remain the same unless more paint is added
   *     - When all three colors are equal, the gray that is created should be more blackish/brownish
   *     - When white paint is added, saturation decreases and brightness increases.
   */
  int[] getColor() {
    int[] colors = new int[4]; 
    float volume = this.getNonWhiteVolume();
      
   float maxColorValue = max(this.r, this.y, this.b);
   float[] rgb = rybToRGB(this.r / maxColorValue, this.y / maxColorValue, this.b / maxColorValue);
    
//    println(rgb[0] + ", " + rgb[1] + ", " + rgb[2]);
    
    colors[0] = int(rgb[0] * 255); // Red
    colors[1] = int(rgb[1] * 255); // Yellow
    colors[2] = int(rgb[2] * 255); // Blue
    colors[3] = this.getBrushOpacity(); // Transparency based on volume

    // println("Current color is (" + colors[0] + ", " + colors[1] + ", " + colors[2] + ")"); // DEBUG

    // After mixing the color we change the color based on the amount of white paint involved.
    if (this.w > 0) {
      float maxColor = max(colors[0], colors[1], colors[2]);
      float minColor = min(colors[0], colors[1], colors[2]);
      float whitePercent = this.w / this.getVolume();

      // Brightness
      // As the brightness increases, the percent of each color increases to 255 based
      // on its proportion of the maximum value color.
      //
      // For example, given (128, 64, 0) and adding 100% white gives you (255, 128, 0)
      float brightnessRange = 255 - maxColor;
      for (int i = 0; i < 3; i++) {
        colors[i] += int(brightnessRange * whitePercent * (colors[i] / brightnessRange));
      }


      // Saturation
      // More white decreases the saturation.
      // When you decrease the saturation, you increase the value of colors
      // proportionally to equal the highest value.
      // E.g. for RGB(85, 170, 0); Maximum is 170.

      // Move each color whitePercent of the way from its current value to the max
      for (int i = 0; i < 3; i++) {
        if (colors[i] != maxColor) {
          // Don't adjust maximum color
          colors[i] += int((maxColor - colors[i]) * whitePercent);
        }
      }
      
      // Special case: if white is all volume of paint can, color is (255, 255, 255)
      if (whitePercent == 1) {
        colors[0] = 255;
        colors[1] = 255;
        colors[2] = 255;
      }
      
      // println("Current color is (" + colors[0] + ", " + colors[1] + ", " + colors[2] + ") after white processing");
    }
    return colors;
  }

  // Create a string to send to the Arduino board controlling the paint bucket display
  // Expected format is 0,0,0,0,0,0,0,0,0,0,0,0 where each number represents the intensity
  // of one of the colors from bottom to top, R G B
  String calculateSerialBucketColor() {
    int colors[] = this.getColor();
    int serialColors[] = {0,0,0,0,0,0,0,0,0,0,0,0};
    float volumePercentage = this.getVolume() / VOLUME_OF_CAN;
    
    // TODO There is a smarter, more efficient way to write this
//    for (int i = 1; i <= 4; i++) {
//    }
    
    // Put any color into the lowest tier
    if (volumePercentage > 0) {
      serialColors[0] = colors[0];
      serialColors[1] = colors[1];
      serialColors[2] = colors[2];
    }
    
    if (volumePercentage > .25) {
      serialColors[3] = colors[0];
      serialColors[4] = colors[1];
      serialColors[5] = colors[2];
    }
    
    if (volumePercentage > .5) {
      serialColors[6] = colors[0];
      serialColors[7] = colors[1];
      serialColors[8] = colors[2];
    }
    
     if (volumePercentage > .75) {
      serialColors[9] = colors[0];
      serialColors[10] = colors[1];
      serialColors[11] = colors[2];
    }
    
    StringBuilder s = new StringBuilder();
    
    for (int i = 0; i < serialColors.length; i++) {
      s.append(serialColors[i]);
      s.append(",");
    }
    s.deleteCharAt(s.length()-1);
    
    return s.toString();
  }
  
  String getSerialBucketColor() {
    return this.serialBucketColor;
  }
  
  boolean serialBucketColorHasChanged() {
    String s = calculateSerialBucketColor();
    boolean changed = !s.equals(this.serialBucketColor);
    if (changed) {
      // Store new changed value
      this.serialBucketColor = s;
    }
    return changed;
  }
  
  void sendSerialBucketColor() {
    if (this.serialBucketColorHasChanged()) {
      // Send new value to bucket arduino
      // println("Bucket value changed to"); // DEBUG
      // println(this.serialBucketColor);
      if (paintSerialReady) {
        paintPort.write(this.serialBucketColor);
      }
    }
  }

  float getVolume() {
    return this.r + this.y + this.b + this.w;
  }

  float getNonWhiteVolume() {
    return this.r + this.y + this.b;
  }

  float[] getVolumes() {
    float[] volumes = new float[4];
    volumes[0] = this.r;
    volumes[1] = this.y;
    volumes[2] = this.b;
    volumes[3] = this.w;
    return volumes;
  }

  // Display the current volumes of different paint cans for debugging.
  String getVolumesString() {
    float[] volumes = this.getVolumes();
    return "(" + volumes[0] + ", " + volumes[1] + ", " + volumes[2] + ", " + volumes[3] + ")";
  }

  /*
   * When the volume of paint is near empty, gradually reduce the opacity so that the paint
   * looks like it is running out. Returns an alpha channel value from 0 (transparent) to 255 (opaque).
   */
  int getBrushOpacity() {
    float volume = this.getVolume();
    if (volume < PAINT_OPACITY_THRESHOLD) {
      return int(volume / PAINT_OPACITY_THRESHOLD * 255);
    } else {
      return 255;
    }
  }

// The code for a RYB to RGB conversion is adapted from Appendix A,
// "C Code Demonstrating RYB to RGB Conversion" from 
// "Paint Inspired Color Compositing" by Nathan Gossett and Baoquan Chen
// http://www.dtc.umn.edu/~gossett/publications/ryb_TR.pdf
//
// See also calculator at http://www.paintassistant.com/rybrgb.html

   // Perform a biased (non-linear) interpolation between values A and B 
   // using t as the interpolation factor. 
   float cubicInt(float t, float A, float B) { 
     float weight = t * t * (3 - 2 * t);
     return A + weight * (B - A);
   } 

    // Given RYB values iR, iY, and iB, return RGB values oR, oG, and oB
  float[] rybToRGB(float iR, float iY, float iB) { 
    float x0, x1, x2, x3, y0, y1; 
    float[] rgb = new float[3];
    
    // red 
    x0 = cubicInt(iB, 1.0, 0.163); 
    x1 = cubicInt(iB, 1.0, 0.0); 
    x2 = cubicInt(iB, 1.0, 0.5); 
    x3 = cubicInt(iB, 1.0, 0.2); 
    y0 = cubicInt(iY, x0, x1); 
    y1 = cubicInt(iY, x2, x3); 
    rgb[0] = cubicInt(iR, y0, y1);
    
    // green 
    x0 = cubicInt(iB, 1.0, 0.373); 
    x1 = cubicInt(iB, 1.0, 0.66); 
    x2 = cubicInt(iB, 0.0, 0.0); 
    x3 = cubicInt(iB, 0.5, 0.094); 
    y0 = cubicInt(iY, x0, x1); 
    y1 = cubicInt(iY, x2, x3); 
    rgb[1] = cubicInt(iR, y0, y1); 
  
    // blue 
    x0 = cubicInt(iB, 1.0, 0.6); 
    x1 = cubicInt(iB, 0.0, 0.2); 
    x2 = cubicInt(iB, 0.0, 0.5); 
    x3 = cubicInt(iB, 0.0, 0.0); 
    y0 = cubicInt(iY, x0, x1); 
    y1 = cubicInt(iY, x2, x3); 
    rgb[2] = cubicInt(iR, y0, y1); 
    
    return rgb;
  }

}


