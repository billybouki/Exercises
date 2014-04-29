/*
This is an example on how to communicate to vvvv 
using data encoded as strings.
For more about Arduino and vvvv check:
http://vvvv.org/documentation/arduino

To see the physical output plug an LED into the Arduino board 
between the pin (defined by the 'Pin number' in the vvvv patch, 
this should be one of PWM pins of the board) and 
the GND (ground) pin. Short leg of the LED (it is '-') 
goes to the GND.
*/


#include <Servo.h> 

Servo myservo1;
Servo myservo2;
Servo myservo3;
Servo myservo4;
Servo myservo5;
Servo myservo6;
Servo myservo7;
Servo myservo8;
Servo myservo9;

const int bufferSize = 110; // how big is the buffer

char buffer[bufferSize];  // Serial buffer
char commandBuffer[10];   // array to store a command
      // array to store a pin number 


char valueBuffer1[10];     // array to store a value
char valueBuffer2[10]; 
char valueBuffer3[10];
char valueBuffer4[10];
char valueBuffer5[10];
char valueBuffer6[10];
char valueBuffer7[10];
char valueBuffer8[10];
char valueBuffer9[10];


int ByteCount;            // how many bytes arrived
boolean ledON;            // state of the LED
            // pinNumber 
int value1;                // brightness value
int value2;
int value3;
int value4;
int value5;
int value6;
int value7;
int value8;
int value9;

void setup() 
{
    //start the serial communication at the speed of 9600 baud
    Serial.begin(9600);    
    
    myservo1.attach(10); 
    myservo2.attach(9);
    myservo3.attach(8);
    myservo4.attach(7);
    myservo5.attach(6);
    myservo6.attach(5);
    myservo7.attach(4);
    myservo8.attach(3);
    myservo9.attach(2);
     // turn on motor
  
}



 
void loop() 
{
    //read the data and parse it
    SerialParser();
    
    //if something arrived 
    if (ByteCount > 0) 
    {
      //send some data back to vvvv
      //the values are encoded as ASCII characters
      //the last print command sends '\r\n' at the end
      //this defines the end of the message
      Serial.print(millis());
      Serial.print(",");
 
      Serial.print(value1);
      Serial.print(",");
      Serial.print(value2);
      Serial.print(",");
      Serial.print(value3);
      Serial.print(",");
      Serial.print(value4);
      Serial.print(",");
      Serial.println(value5);
      
      //set the state of the pin according to the string received from vvvv 
      if (ledON)
      {

        myservo1.write(value1);
        myservo2.write(value2);
        myservo3.write(value3);
        myservo4.write(value4);
        myservo5.write(value5);
        myservo6.write(value6);
        myservo7.write(value7);
        myservo8.write(value8);
        myservo9.write(value9);
      }
   
      }
    
}

void SerialParser() 
{
  ByteCount = -1;
  
  // if something has arrived over serial port
  if (Serial.available() > 0)
  {
    //read the first character
    char ch = Serial.read();
    
    //if it's 's', then it's the start of the message
    if (ch == 's')
    {
      //read all bytes of the message until the newline character ('\n')
       ByteCount =  Serial.readBytesUntil('\n',buffer,bufferSize); 
       
       //if the number of arrived bytes > 0
       if (ByteCount > 0) 
       {
            // copy the string until the first ','
            strcpy(commandBuffer, strtok(buffer, ","));
                    
            // copy the same string until the next ',' 
            strcpy(valueBuffer1, strtok(NULL, ","));
            strcpy(valueBuffer2, strtok(NULL, ","));
            strcpy(valueBuffer3, strtok(NULL, ","));
            strcpy(valueBuffer4, strtok(NULL, ","));
            strcpy(valueBuffer5, strtok(NULL, ","));
            strcpy(valueBuffer6, strtok(NULL, ","));
            strcpy(valueBuffer7, strtok(NULL, ","));
            strcpy(valueBuffer8, strtok(NULL, ","));
            strcpy(valueBuffer9, strtok(NULL, ","));
            
            //check the documentation about strtok() at:
            //http://www.gnu.org/software/libc/manual/html_node/Finding-Tokens-in-a-String.html
         
            //check the arrived command and set the LED state
            //this is how to compare two char arrays (simple strings)
            //if they are equal, strcmp returns 0
            if (strcmp(commandBuffer, "LED_ON") == 0)
            {
              ledON = true;
            }
            else
            {
              ledON = false;
            }
            

   
            // convert the sting into a 'float' value and bring it to (0..255) range;
            value1 = atof(valueBuffer1) * 180; 
            value2 = atof(valueBuffer2) * 180; 
            value3 = atof(valueBuffer3) * 180; 
            value4 = atof(valueBuffer4) * 180; 
            value5 = atof(valueBuffer5) * 180;  
            value6 = atof(valueBuffer6) * 180;
            value7 = atof(valueBuffer7) * 180;
            value8 = atof(valueBuffer8) * 180;
            value9 = atof(valueBuffer9) * 180;
       }
       
       // clear contents of buffer
       memset(buffer, 0, sizeof(buffer));   
       Serial.flush();
    }
  }
}
