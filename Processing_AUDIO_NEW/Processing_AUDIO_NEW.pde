/**
 * Processing interface to trigger sound plaback from Arduino
 * Using capacitive touch sensors to trigger playback over a threshold
 *
 * Built for Bompas & Parr
 *
 * By Luke Sturgeon <luke.sturgeon@network.rca.ac.uk>
 */

import controlP5.*;
import processing.serial.*;
import ddf.minim.*;

// change the expected number of sensor readings
// coming from the Arduino
final int NUM_SENSORS = 3;
final int NUM_SAMPLES = 16;
final int DEFAULT_MIN_VALUE = 150;
final int DEFAULT_MAX_VALUE = 1500;

// for any error messages
String errorMessage = "";
boolean error = false;

Minim minim;
ControlP5 cp5;
Serial port;

String[] files = {
  "bee sample.mp3", 
  "best tasting fruit whatever the weather Wanna 2.mp3", 
  "cultivating strawberries Wanna.mp3", 
  "fertigation LOlins.mp3", 
  "glass houses LED 3 LOlins.mp3", 
  "new varieties Wanna.mp3", 
  "picking in the morning Wanna.mp3", 
  "pineberry LOlins.mp3", 
  "room temperature Wanna.mp3", 
  "soil conditions Wanna.mp3",
  "strasberries LOlins.mp3",
  "strawberries don't like high humidity Wanna.mp3",
  "strawberry being picked 1.mp3",
  "strawberry being picked 2.mp3",
  "the older the plant Wanna.mp3",
  "we can freeze Wanna.mp3"
};

AudioPlayer[] samples = new AudioPlayer[NUM_SAMPLES];

int currentSample;
boolean lockPlayer = true;

int[] sensorValues = new int[NUM_SENSORS];
int[] smoothValues = new int[NUM_SENSORS];
int[] minValues = new int[NUM_SENSORS];
int[] maxValues = new int[NUM_SENSORS];
Slider[] slider = new Slider[NUM_SENSORS];
boolean[] contact = new boolean[NUM_SENSORS];

//-----------------------------------------------------------------
void setup() {
  size(1024, 600);

  // setup sound
  println(files.length);
  minim = new Minim(this);
  for (int i = 0; i < files.length; i++) {
    samples[i] = minim.loadFile(files[i]);
  }

  // setup controllers
  cp5 = new ControlP5(this);

  // load previous settings
  String[] prevSettings;
  prevSettings = loadStrings("settings.txt");

  // create all controls
  for (int i = 0; i < NUM_SENSORS; i++) {
    // defaults
    contact[i] = false;

    if (prevSettings != null) {
      String[] n = split(prevSettings[i], ",");
      minValues[i] = Integer.parseInt(n[0]);
      maxValues[i] = Integer.parseInt(n[1]);
    } else
    {
      minValues[i] = DEFAULT_MIN_VALUE;
      maxValues[i] = DEFAULT_MAX_VALUE;
    }

    // controls
    slider[i] = cp5.addSlider("#"+i)
      .setBroadcast(false)
        .setId(i)
          .setPosition(20, 50+40*i)
            .setSize(200, 20)
              .setHandleSize(10)
                .setRange(0, 5000)
                  .setValue(minValues[i])
                    .setBroadcast(true);
  }

  // create the volume toggle
  // create a toggle
  cp5.addToggle("lockPlayer")
    .setPosition(20, 50+40*NUM_SENSORS)
      .setSize(20, 20)
        .setLabel("Lock player");

  //  printArray(Serial.list());
  // Connect to the arduino
  String portName = "/dev/cu.usbmodem621";
  port = new Serial(this, portName, 9600);
  port.clear();
  port.bufferUntil('\n');
}

//-----------------------------------------------------------------
void draw() 
{
  if (error) {
    background(200, 20, 20);
    text(errorMessage, 20, 35);
    cp5.hide();
    return;
  }

  background(0);

  smoothValues();

  // labels
  text("THRESHOLD", 20, 30);
  text("SENSOR", 300, 30);
  text("SMOOTH", 400, 30);
  text("PRESSURE", 500, 30);

  // interface
  pushMatrix();
  translate(0, 65);

  // show the current data

  int v, minv, maxv;

  for (int i = 0; i < NUM_SENSORS; i++) {
    v = sensorValues[i];
    minv = minValues[i];
    maxv = maxValues[i];

    text(v, 300, 40*i);
    text(smoothValues[i], 400, 40*i);

    stroke(255);
    noFill();
    rect(500, -15+40*i, 200, 20);
    fill(255);
    noStroke();
    rect(500, -15+40*i, map(constrain(v, minv, maxv), minv, maxv, 0, 200), 20);
  }

  popMatrix();

  if (samples[currentSample].isPlaying()) {
    text("Playing \""+files[currentSample]+"\"", 20, height-70);
  } else {
    text("Not playing", 20, height-70);
  }

  text("islocked: "+lockPlayer, 20, height-50);

  text("'x' stop sound | 's' save settings | 'r' reset settings", 20, height-30);
}

//-----------------------------------------------------------------
void onTouchStart(int sensor) {
  println("START TOUCH #"+sensor);

  if (lockPlayer == true) 
  {
    //lock until the current sample has stopped
    if (samples[currentSample].isPlaying() == false) 
    {
      stopAllSounds();
      playNewSound();
    } else
    {
      println("locked");
    }
  } else 
  {
    stopAllSounds();
    playNewSound();
  }
}

//-----------------------------------------------------------------
void onTouchStop(int sensor) {
  println("STOP TOUCH #"+sensor);
}


//-----------------------------------------------------------------
void stopAllSounds() {
  // stop all playing samples
  for (int i = 0; i < NUM_SAMPLES; i++) {
    samples[i].pause();
  }
}


//-----------------------------------------------------------------
void playNewSound() {
  // make sure it's not the same sample twi ce
  int newSample = currentSample;  
  while (newSample == currentSample) {
    newSample = (int)random(0, samples.length);
  }

  // now start the new sample
  currentSample = newSample;
  samples[currentSample].play(0);
}

//-----------------------------------------------------------------
void smoothValues() {
  for (int i = 0; i < NUM_SENSORS; i++) 
  {
    // TOUCH START
    if (contact[i]==false && sensorValues[i] > minValues[i]) {
      smoothValues[i] = sensorValues[i];
      contact[i] = true;
      // event
      onTouchStart(i);
    }

    // TOUCH STOP
    if (contact[i]==true && sensorValues[i] < minValues[i]) {
      contact[i] = false;
      onTouchStop(i);
    }

    // TOUCHING
    if (contact[i]==true && sensorValues[i] > minValues[i]) {
      smoothValues[i] = sensorValues[i];
    }

    // NOT TOUCHING
    if (contact[i]==false && smoothValues[i] > 0) {
      // go down a bit
      smoothValues[i] -= 75;

      // constrain the end
      if (smoothValues[i] <0) {
        smoothValues[i] = 0;
      }
    }
  }
}

//-----------------------------------------------------------------
void serialEvent( Serial p ) {

  // parse and trim incoming data from arduino
  String str = p.readString();
  str = trim(str);

  //  println("str ("+str.length()+") = " + str);
  if (str.length() >= 3) {
    // split string in to array of ints
    int[] a = int( split(str, "\t") );

    if (a.length == NUM_SENSORS) {
      arrayCopy(a, sensorValues);
      error = false;
      cp5.show();
    } else {
      errorMessage = "The wrong number of values from the Arduino!";
      error = true;
      cp5.hide();
    }
  }
}

//-----------------------------------------------------------------
void controlEvent(ControlEvent event) {
  if (event.getId() > -1) {
    // must be a note range
    minValues[event.getId()] = int(event.getController().getArrayValue(0));
    maxValues[event.getId()] = int(event.getController().getArrayValue(1));
  }
}

//-----------------------------------------------------------------
void keyPressed() {

  // stop playing any sounds
  if (key == 'x') {
    for (int i = 0; i < NUM_SAMPLES; i++) {
      samples[i].pause();
    }
  }

  // save current settings
  if (key == 's') {
    String[] toSave = new String[NUM_SENSORS];
    for (int i = 0; i < NUM_SENSORS; i++) {
      toSave[i] = minValues[i] + "," + maxValues[i];
    }
    printArray(toSave);
    saveStrings("settings.txt", toSave);
  }

  // reset current settings
  if (key == 'r') {
    for (int i = 0; i < NUM_SENSORS; i++) {
      slider[i].setValue(DEFAULT_MIN_VALUE);
    }
  }
}

