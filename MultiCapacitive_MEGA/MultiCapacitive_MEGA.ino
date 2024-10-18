/**
 * Multi-input capacitive touch sensor for midi control
 *
 * Built for Bompass & Parr - musical installations
 *
 * @author Luke Sturgeon <luke.sturgeon@network.rca.ac.uk>
 */


#include <CapacitiveSensor.h>


#define NUM_SENSORS 3


CapacitiveSensor sensors[NUM_SENSORS] = {
  CapacitiveSensor(2, 3),
  CapacitiveSensor(10, 11),
  CapacitiveSensor(7, 8)
};

// max number of sensors is 12
// so only need up to 12 values stored
int sensorValues[12];

void setup()
{
  Serial.begin(9600);
}

void loop()
{
  // loop through each available sensor
  for (int i = 0; i < NUM_SENSORS; i++)
  {
    // get the current sensor values
    sensorValues[i] = sensors[i].capacitiveSensor(100);

    // output to serial
    Serial.print(sensorValues[i]);
    Serial.print('\t');
  }

  // finish serial with a newline
  Serial.println("");

  // give a little delay to slow things down
  delay( 100 );
}
