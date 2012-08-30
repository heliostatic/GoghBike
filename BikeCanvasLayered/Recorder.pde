/*
 * Recorder
 * Gogh Bike by Ben Cohen, Ryan Greenberg, Joyce Tsai
 */

class Recorder {
    String filename; 
    Bike bike;
    PrintWriter output;
  
    // This should be a static method but it isn't because Processing won't allow that
    String createFileName() {
      return String.format("%d-%d-%d %d-%d-%d.txt", year(), month(), day(), hour(), minute(), second());
    }
  
    Recorder(String path, Bike bike) {
      this.filename = path + this.createFileName();
      this.bike = bike;
      if (RECORDING_ENABLED) {
      this.output = createWriter(this.filename);
      } else {
        println("Recording is disabled...");
      }
    }

    // Write object watched by recorder to 
    void write() {
      if (RECORDING_ENABLED) {
      this.write(this.bike.state());
      }
    }

    // Write string to output file
    void write(String s) {
      this.output.println(s);
    }
    
    // Get data about the sketch used to replay it
    void headers() {
    }
    
    void close() {
      if (RECORDING_ENABLED) {
      this.output.flush(); // Writes the remaining data to the file
      this.output.close(); // Finishes the file
      }
    }
}
