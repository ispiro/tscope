/**
 * Tachistoscope
 * ispiro
 */
import processing.opengl.*;
import java.util.Map;
import themidibus.*;

/******************* USEFUL GLOBALS *******************/

int masterWidth = 1680;
int myWidth = 1280;
int myHeight = 740;
boolean doubleMode = false;
float previewScale = 0.25;
int randomDelay = 0;
int currentSearch = 30;

/******************************************************/

int frameSpeed = 10;
int brightness = 255;
int opacity = 1;
int imageSaturation = 255;
int currentImage = 0;
int bufferSize = 30;
int loopSize = 30;
int bufferOffset = 0;
int tintHue = 0;
int tintAmount = 0;
int count = 0;
int freezeImage = -1;
int attempt = 0;
int lastTime;
int lastBuffer = 0;
int nextSet = -1;
int previewWidth;
int kernelSize = 1;
int[] kernel = {200, 160, 140, 120, 100, 80, 60};

String statusMessage;
String searchString;
String search;

float statusCount = 0;
float randomFrame;

boolean newSearch;
boolean verbose = true;
boolean randomness = false;
boolean updateSpeed = false;
boolean ready = false;
boolean filling = false;

HashMap<String, String[]> images;
ArrayList searches;
PFont font;
PImage buffer[] = new PImage[100];
PImage grays[] = new PImage[100];
MidiBus myBus;

/******************* SETUP *******************/

void setup() {
  loadCachedSearches();
  lastTime = millis();
  int windowWidth = myWidth;
  if (doubleMode) {
    previewWidth = (int)(myWidth * previewScale);
    windowWidth = myWidth + previewWidth;
  }
  size((int)(windowWidth), (int)(myHeight), OPENGL);
  if (doubleMode) {
    frame.setLocation(masterWidth-previewWidth, -20);
  }
  colorMode(HSB);
  frameRate(frameSpeed);
  doRandomStuff(true);

  myBus = new MidiBus(this, 0, 1);
  font = loadFont("CourierNew36.vlw"); 
  textFont(font, 32); 
  fillBuffer();
}


void initFrame() {
  frame.removeNotify();
  frame.setUndecorated(true);
  frame.addNotify();
}


void drawTexture(PImage img) {
  float displayWidth;
  float displayHeight;
  float aspect = (float)img.width/(float)  img.height;
  displayWidth = aspect * height;
  displayHeight = height;

  if (displayWidth > myWidth) {
    displayWidth = myWidth;
    //displayHeight = myWidth/aspect;
  }

  if (doubleMode) {
    int startX = (int)(myWidth*previewScale) + abs((int)((displayWidth - myWidth) / 2));   
    image(img, startX, 0, displayWidth, displayHeight);
    
    startX = (int)((myWidth*previewScale - displayWidth*previewScale) / 2);
    image(img, startX, 0, displayWidth * previewScale, displayHeight*previewScale);
  } 
  else {
    int startX = (int)((myWidth - displayWidth) / 2);
    image(img, startX, 0, displayWidth, displayHeight);
  }
}


void draw() {

  if (updateSpeed) {
    frameRate(frameSpeed);
    updateSpeed = false;
  }

  updateBuffer();
  doRandomStuff(false);
  background(0);

  if (!ready) return;

  int theTint = tintHue;
  if (tintHue == 0) {
    float milli = millis();
    float milliNoise = noise(milli*.0001) * 2 * (noise(milli) - .5); 
    theTint = (int)(abs(milliNoise) * 2 * 360.0);
  }

 
  if (freezeImage != -1) {  
    tint(theTint, tintAmount, brightness);
    drawTexture(buffer[freezeImage]);
    tint(theTint, tintAmount, brightness, imageSaturation);
    drawTexture(grays[freezeImage]);

  } else {
    if (kernelSize == 1) {
      tint(theTint, tintAmount, brightness);
      drawTexture(buffer[currentImage]);
      tint(theTint, tintAmount, brightness, imageSaturation);
      drawTexture(grays[currentImage]);
    } else {
      
      
    for (int d = 0; d < kernelSize; d++) {
    
      int pos = currentImage + d;
      while (pos >= bufferSize) {
        pos -= bufferSize;
      }

      //tint(theTint, tintAmount, brightness, kernel[d]);
      //drawTexture(buffer[pos]);
      tint(theTint, tintAmount, brightness, kernel[d]);
      drawTexture(grays[pos]);
    
    }
  }
  }
  count++;
  currentImage = count + bufferOffset;

  currentImage = bufferOffset + ((count + bufferOffset) % loopSize);
  while (currentImage >= bufferSize) {
    currentImage -= bufferSize;
  }

  if (statusCount > 0) {
    statusCount-= (10.0 / frameSpeed);
    if (verbose || statusMessage == "Verbose off") {
      fill(255, 0, 0, 255 * (statusCount / 20.0));
      text(statusMessage, 50-2, 50);
      fill(255, 0, 0, 255 * (statusCount / 20.0));
      text(statusMessage, 50+2, 50);
      fill(255, 0, 0, 255 * (statusCount / 20.0));
      text(statusMessage, 50, 50+2);
      fill(255, 0, 0, 255 * (statusCount / 20.0));
      text(statusMessage, 50, 50-2);
      
      fill(70, 255, 255, 255 * (statusCount / 20.0));
      text(statusMessage, 50, 50);

    }
  }
}


void setStatus(String stat) {
  setStatus(stat, false);
}

void setStatus(String stat, boolean slow) {
  statusMessage = stat;
  if (slow) statusCount =  200;
  else statusCount = 20;
}

/******************* KEYBOARD *******************/

void keyPressed() {

  /*if (newSearch) {
    if (keyCode == ENTER) {
      newSearch = false;
      setStatus("Searching...");
      return;
    }
    if (keyCode == BACKSPACE && searchString.length() > 0) {
      searchString = searchString.substring(0, searchString.length()-1);
    }
    if (((key>='a')&&(key<='z')) || ((key>='0')&&(key<='9')) || key==' ') {
      searchString += key;
    }
    setStatus("Search: " + searchString, true);
    return;
  }*/
  
  if (key == 'v') {
    verbose = !verbose;
    if (verbose) setStatus("Verbose on");
    else setStatus("Verbose off");
  }

  if (key == ' ') {

    currentSearch++;
    if (currentSearch >= images.size()) {
      currentSearch = 0;
    }

    fillBuffer();
    search = (String)searches.get(currentSearch);
    if (search.length() > 13) {
      setStatus(search.substring(0,10) + "...");
    } else {
      setStatus(search);
    }

    fillBuffer();
  }

  if (key == '=') {
    ready = true;
    if (frameSpeed < 90) {
      frameSpeed = frameSpeed + 1;
      frameRate(frameSpeed);
      setStatus("FPS " + frameSpeed);
    }
  }

  if (key == '-') {
    ready = true;
    if (frameSpeed > 1) {
      frameSpeed = frameSpeed - 1;
      frameRate(frameSpeed);
      setStatus("FPS " + frameSpeed);
    }
  }
  int k2[];
  if (key == 'k') {
    kernelSize+=2;
    if (kernelSize > 7) {
      kernelSize = 1;
    }
   
    setStatus("Blur " + kernelSize);

   }

  if (key == 'm') {
    randomness = !randomness;
    if (randomness) {
      randomDelay = 10000;
    } else {
      randomDelay = 0; 
    }    
    setStatus("Rnd " + randomDelay); 
  }

  if (key == 's') {
    //newSearch = true;
    //searchString = "";
    //setStatus("Search: ", true);
    
    String lines[] = loadStrings("http://localhost:8888/list.php");
    print(lines[0]);
    search = lines[0];
    fillBuffer();

  }
  
  if (key == 'r') {
    randomizeBuffer();
  }
}


void doRandomStuff(boolean force) {

  if (randomDelay == 0) return;

  int elapsed = millis() - lastTime;  

  if (randomDelay != 0 && elapsed > randomDelay) {
    lastTime = millis(); 
    imageSaturation = 127 + (int)random(227);
    tintHue = (int)random(255);
    tintAmount = (int)random(255);
    
    if (random(10) > 5) {
     tintHue = 0;
     imageSaturation = 255;
     tintAmount = 255; 
    }
    
    currentSearch = (int)random(0,searches.size()-2);
      search = (String)searches.get(currentSearch);

    if (currentSearch >= images.size()) {
      currentSearch = 0;
    }

    fillBuffer(); 

    frameSpeed = (int) random(5, 40);
    frameRate(frameSpeed);
    if (verbose) setStatus("FPS " + frameSpeed);
  }
}



void loadCachedSearches() {
  searches = new ArrayList();
  images = new HashMap<String, String[]>();

  File file = new File(sketchPath + "/cache");
  if (file.isDirectory()) {
    String names[] = file.list();
    for (int i = 0; i < names.length; i++) {
      if (!names[i].substring(0, 1).equals(".")) {
        File subdir = new File(sketchPath + "/cache/" + names[i]);
        if (subdir.isDirectory()) {
          searches.add(names[i]);
          images.put(names[i], subdir.list());
        }
      }
    }
  }
  search = (String)searches.get(0);
  println(images);
  println(searches);
}


void fillBuffer() {
  attempt = 0;
  lastBuffer = 0;
  filling = true;
}

PImage img;
PImage cp;

void updateBuffer() {

  //search = (String)searches.get(currentSearch);
  String[] ims = images.get(search);

  if (lastBuffer >= ims.length) {
    bufferSize = ims.length;
    lastBuffer = 0;
    filling = false; 
    ready = true;
  }  

  if (!filling) return;
  
  while (true) {
    attempt++;

    String fname = "cache/" + search + "/" + ims[lastBuffer];
    img = loadImage(fname);
    if (img != null) {
      buffer[lastBuffer] = img;

      cp = img.get();
      cp.filter(GRAY);
      grays[lastBuffer] = cp;

      println("Found " + fname);
      lastBuffer++;
      return;
    }
  }
}



void randomizeBuffer() {

  for (int i = 0; i < 32; i++) {
    int rs = (int)random(searches.size());
    String search = (String)searches.get(rs);
    String[] ims = images.get(search);
    int ri =  (int)random(ims.length);
    String fname = "cache/" + search + "/" + ims[ri];
    img = loadImage(fname);
    if (img != null) {
      buffer[i] = img;
      cp = img.get();
      cp.filter(GRAY);
      grays[i] = cp;
      println("Randomized " + fname);
    }
  }
  bufferSize = 32;
}

/******************* MIDI SUPPORT *******************/

void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);

  freezeImage = pitch % buffer.length;
  opacity = (int)(velocity * 2);
  if (opacity > 255) opacity = 255;
}

void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  println();
  println("Note Off:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
  freezeImage = -1;
  
  //if (pitch == 120) {
  //  randomizeBuffer();
  //}
  
}

void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  println();
  println("Controller Change:");
  println("--------");
  println("Channel:"+channel);
  println("Number:"+number);
  println("Value:"+value);
  if (number == 7) {
    frameSpeed = (int)(value * .66) + 1;
    updateSpeed = true;
    setStatus("FPS " + frameSpeed);
  } 
  else if (number == 73) {
    imageSaturation = (256- (value * 2));
    setStatus("Sat " + (value * 2));
  } 
  else if (number == 71) {
    brightness = value * 2;
    setStatus("Lum " + brightness);
  }  
  else if (number == 72) {
    tintAmount = value * 2;
    setStatus("Tin " + tintAmount);
  } 
  else if (number == 74) {
    tintHue = value * 2;
    setStatus("Hue " + tintHue);
  } 
  else if (number == 5) {
    loopSize = 1 + (int) (value  / 4);
    setStatus("Len " + loopSize);
  } 
  else if (number == 1) {    
    randomDelay = 0;
    if (value != 0) randomDelay = (15000 - (value * 100));
    setStatus("Rnd " + value);
  } 
  else if (number == 84) {
    bufferOffset = (int) (value  / 4);
    setStatus("Off " + bufferOffset);
  }
  else if (number == 93) {
    currentSearch = value;
    fillBuffer();
     search = (String)searches.get(currentSearch);
    if (search.length() > 13) {
      setStatus(search.substring(0,10) + "...");
    } else {
      setStatus(search);
    }
  }
  else if (number == 10) {
    currentSearch = 128 + value;
    if (currentSearch >= searches.size()) currentSearch = searches.size() - 1;
    fillBuffer();
     search = (String)searches.get(currentSearch);
    if (search.length() > 13) {
      setStatus(search.substring(0,10) + "...");
    } else {
    setStatus(search);
    }
  }
}

