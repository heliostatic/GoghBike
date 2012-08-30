/*
 * Playback
 * Gogh Bike by Ben Cohen, Ryan Greenberg, Joyce Tsai
 */

class Player {
  Bike bike;
  BufferedReader reader;
  String line;
  boolean eof;
  int playbackSpeed;

  Player(String path, Bike bike) {
    println("Creating player...");
    this.reader = createReader(path);
    this.eof = false;
    this.bike = bike;
    this.bike.playback = true;
    this.playbackSpeed = 1;
    this.bike.speed = 10; // This is a bit hacky, but the bike's speed is set to be non-zero so that it doesn't exit from its own draw method
  }

  void advance() {
    if (this.eof) {
      return;
    }
      this.read();
      if (this.line == null) {
        // Stop reading because of an error or file is empty
        println("Reached end of recording");
        this.bike.speed = 0;
        this.eof = true;
      } 
      else {
        this.bike.loadState(line);
      }
  }

  void read() {
    try {
      this.line = this.reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      this.line = null;
    }
    // println("Read: " + this.line); // DEBUG
  }

  void increasePlaybackSpeed() {
    this.playbackSpeed *= 2;
    println("Playback speed set to " + this.playbackSpeed);
  }
  
  void decreasePlaybackSpeed() {
    this.playbackSpeed = (int) (this.playbackSpeed * 0.5 >= 1 ? this.playbackSpeed * 0.5 : 1);
    println("Playback speed set to " + this.playbackSpeed);
  }

  void setPlaybackSpeed(int i) {
    this.playbackSpeed = i;
  }

  void close() {
    try {
    this.reader.close(); // Writes the remaining data to the file
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
}
