#include "WProgram.h"
void setup();
int readSerialString (char *strArray);
void resetSerialString (char *strArray, int length);
void parseStringToValues(char *strArray);
void loop();
int pwmVal[14];                                                               // PWM values for 12 channels - 0 & 1 included but not used
int i, j, k, l, x, y, z, bufsize, pot;                                        // variables for various counters
char serialData[50];


void setup(){
  Serial.begin(115200);
  DDRD=0xFC;      // direction variable for port D - make em all outputs except serial pins 0 & 1
  DDRB=0xFF;      // direction variable for port B - all outputs 
}

// read a string from the serial and store it in an array
// you must supply the array variable
// readSerialString function by
// Tod E. Kurt <tod@todbot.com>
// Reads from serial until the termination character is received
int readSerialString (char *strArray) {
  int i = 0;
  if(!Serial.available()) {
    return 0;
  }
  while (Serial.available()) {
    strArray[i] = Serial.read();
    i++;
  }
  strArray[i] = '\0'; // Terminate string with space
  Serial.flush();
  return 1;
}

void resetSerialString (char *strArray, int length) {
  for (int i = 0; i < length; i++) {
    strArray[i] = '\0';
  }
}

void parseStringToValues(char *strArray)
{ 
   char *ptr = strArray;
   char field[3];
   int n;
   int c = 2;
   while ( sscanf(ptr, "%31[^,]%n", field, &n) == 1 )
   {
      pwmVal[c] = atoi(field);
      ptr += n; /* advance the pointer by the number of characters read */
      if ( *ptr != ',' )
      {
         break; /* didn't find an expected delimiter, done? */
      }
      ++ptr; /* skip the delimiter */
      c++;
   }
}

void loop(){
if(readSerialString(serialData) == 1)
{
    parseStringToValues(serialData);
    resetSerialString(serialData, 50);
}

  PORTD = 0xFC;              // all outputs except serial pins 0 & 1
  PORTB = 0xFF;              // turn on all pins of ports D & B

  for (z=0; z<3; z++){         // this loop just adds some more repetitions of the loop below to cut down on the time overhead of loop above
    // increase this until you start to preceive flicker - then back off - decrease for more responsive sensor input reads
    for (x=0; x<256; x++){
      for( i=2; i<14; i++){    // start with 2 to avoid serial pins
        if (x == pwmVal[i]){
          if (i < 8){    // corresponds to PORTD
            // bitshift a one into the proper bit then reverse the whole byte
            // equivalent to the line below but around 4 times faster
            // digitalWrite(i, LOW);
            PORTD = PORTD & (~(1 << i));
          }   
          else{   
            PORTB = PORTB & (~(1 << (i-8)));         // corresponds to PORTB - same as digitalWrite(pin, LOW); - on Port B pins
          }

        }
      }
    }
  }
  //    }
  //    Serial.println((millis() - time), DEC);     // speed test code

}  

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

