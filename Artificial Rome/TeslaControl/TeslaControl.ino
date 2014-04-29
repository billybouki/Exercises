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

#include <AFMotor.h>

const int bufferSize = 40; // how big is the buffer

char buffer[bufferSize];  // Serial buffer

char commandBuffer1[10];   // array to store a command
char commandBuffer2[10];   // array to store a command

char pinBuffer[3];        // array to store a pin number 

char valueBuffer1[10];
char valueBuffer2[10];    // array to store a value

int ByteCount;            // how many bytes arrived

boolean led1ON; 
boolean led2ON;// state of the LED

int value1;                // brightness value
int value2;

AF_DCMotor motor1(1);
AF_DCMotor motor3(3);

void setup() 
{
    //start the serial communication at the speed of 9600 baud
    Serial.begin(9600);    
      // turn on motor
  motor1.setSpeed(200);
  motor1.run(RELEASE);
  motor3.setSpeed(200);
  motor3.run(RELEASE);
}

 
void loop() 
{
    //read the data and parse it
    SerialParser();
    
    //if something arrived 
    if (ByteCount > 0) 
    {
      Serial.print(millis());
      Serial.print(",");
      Serial.print(value1);
      Serial.print(",");
      Serial.println(value2);
     
      //set the state of the pin according to the string received from vvvv 
      if (led1ON)
      {
        motor1.run(FORWARD);
        motor1.setSpeed(value1);  
      }
      else{
        motor1.run(BACKWARD);
        motor1.setSpeed(value1)  ; }
      }
      
      
       if (led2ON)
      {
        motor3.run(FORWARD);
        motor3.setSpeed(value2);  
      }
      else{
        motor3.run(BACKWARD);
        motor3.setSpeed(value2)  ; }
      
      
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
            strcpy(commandBuffer1, strtok(buffer, ","));
            
            // copy the same string until the next ','
            strcpy(commandBuffer2, strtok(NULL, ","));
     
            // copy the same string until the next ',' 
            strcpy(valueBuffer1, strtok(NULL, ","));
            strcpy(valueBuffer2, strtok(NULL, ","));
            
            //check the documentation about strtok() at:
            //http://www.gnu.org/software/libc/manual/html_node/Finding-Tokens-in-a-String.html
         
            //check the arrived command and set the LED state
            //this is how to compare two char arrays (simple strings)
            //if they are equal, strcmp returns 0
            if (strcmp(commandBuffer1, "LED1_ON") == 0)
            {
              led1ON = true;
            }
            else
            {
              led1ON = false;
            }
            
             if (strcmp(commandBuffer2, "LED2_ON") == 0)
            {
              led2ON = true;
            }
            else
            {
              led2ON = false;
            }

            // convert the sting into a 'float' value and bring it to (0..255) range;
            value1 = atof(valueBuffer1) * 255;  
            value2 = atof(valueBuffer2) * 255;  
       }
       
       // clear contents of buffer
       memset(buffer, 0, sizeof(buffer));   
       Serial.flush();
    }
  }
}
