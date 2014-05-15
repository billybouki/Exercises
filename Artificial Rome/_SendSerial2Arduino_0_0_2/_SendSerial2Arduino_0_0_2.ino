
 #define SHIFTPWM_USE_TIMER2
////////////////////////////////////////select Latch Pin
const int ShiftPWM_latchPin=8;
//
const bool ShiftPWM_invertOutputs = false;
//distirbutes CurrentPeaks,by owm offset
const bool ShiftPWM_balanceLoad = false;

#include <ShiftPWM.h>

unsigned char maxBrightness = 255;
unsigned char pwmFrequency = 75;
unsigned int numRegisters = 2;
unsigned int numOutputs = numRegisters*8;
unsigned int numRGBLeds = numRegisters*8/3;
unsigned int fadingMode = 0;

unsigned long startTime = 0; // start time for the chosen fading mode


//Read some values from vvvv and Apply to Arduino.
//colorsound
int sizeBuffer = 18;
char packetBuffer[18];



void setup()   
{
 
  Serial.begin(9600);
  // Sets the number of 8-bit registers that are used.
  ShiftPWM.SetAmountOfRegisters(numRegisters);
  ShiftPWM.Start(pwmFrequency,maxBrightness);
}



void loop() {
  
if (Serial.available() > 0) 
{
 Serial.readBytes(packetBuffer,sizeBuffer);// 6 is the packetsize
 if( packetBuffer[0]=='<' && packetBuffer[18-1]=='>')
 {
 unsigned char buff [18-2];
 memcpy(buff,packetBuffer+1,18-2);
///////////Now we have a clean input buffer of 4 bytes to use.
ShiftPWM.SetRGB(0, buff[0], buff[1], buff[2]); 
ShiftPWM.SetRGB(1, buff[3], buff[4], buff[5]);
ShiftPWM.SetRGB(2, buff[6], buff[7], buff[8]);
ShiftPWM.SetRGB(3, buff[9], buff[10], buff[11]);
ShiftPWM.SetRGB(4, buff[12], buff[13], buff[14]);
 }
 }

           }
