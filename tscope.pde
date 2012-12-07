/**
 * Tachistoscope
 */

import processing.opengl.*;
import themidibus.*;


String baseURL = "http://localhost/~ispiro/";

boolean local = true;
boolean ready = false;
boolean verbose = true;
boolean randomness = false;
boolean doubleMode = true;

int fixedWidth;
int fixedHeight;
int screenShift = 640;
int bufferSize = 30;

ArrayList searches = new ArrayList();
String statusMessage;
String searchString;
boolean newSearch, recording, playback, filling;


int ks[] = new int[8];
int sequence[];
int step = 0;
int sequenceLength = 0;
int maxSequenceLength = 64;

int currentImage = 0;
int currentSearch = 0;
int currentBufferSize = 0;
int frameSpeed = 10;
int tintHue;
int colorSetting = 1;
int attempt = 0;
int lastTime;
int randomDelay = 40000;
int freezeImage = -1;
int imageSaturation = 255;
float statusCount = 0;
float shrink = .5;
float randomFrame;
int imageWidth;

float aspect;
float displayWidth;
float displayHeight;

PFont font;
PImage buffers[][] = new PImage[bufferSize][100];
PImage buffer[] = new PImage[bufferSize];
PImage grays[] = new PImage[100];
PImage gray;

MidiBus myBus; 

void setup() {
  
  int theWidth = (int)(screen.width * shrink);
  int theHeight = (int)(screen.height * shrink);

  if (fixedWidth != 0 && fixedHeight != 0) {
    theWidth = fixedWidth;
    theHeight = fixedHeight;
  }
  imageWidth = theWidth;
  if (doubleMode) {
    theWidth *= 2;
  }
  size(theWidth, theHeight, OPENGL);

  colorMode(HSB);
  frameRate(frameSpeed);

  loadCachedSearches();
  lastTime = millis();

  myBus = new MidiBus(this, 0, 1);

  font = loadFont("CourierNew36.vlw"); 
  textFont(font, 32); 

  fillBuffer();
  getParent().setLocation(screenShift, 0);
}

void drawTexture(PImage textureImage, int sr) {
  beginShape();
  texture(textureImage);
  vertex(sr+ks[0], ks[1], 0, 0);
  vertex(sr+displayWidth+ks[2], ks[3], textureImage.width, 0);
  vertex(sr+displayWidth+ks[4], displayHeight+ks[5], textureImage.width, textureImage.height);
  vertex(sr+ks[6], displayHeight+ks[7], 0, textureImage.height);
  endShape();
}

void draw() {

  updateBuffer();
  background(0);

  if (!ready) return;

  aspect = (float)buffer[currentImage].width/(float)  buffer[currentImage].height;
  displayWidth = aspect * buffer[currentImage].height;
  displayHeight = buffer[currentImage].height;

  if (displayWidth > buffer[currentImage].width) {
    displayWidth = buffer[currentImage].width;
    displayHeight = buffer[currentImage].width/aspect;
  }

  float startX = (imageWidth - displayWidth) / 2;
  startX = 0;

  if (playback) {
    currentImage = sequence[step];
    step++;
    step = step % sequenceLength;
  }

  if (freezeImage != -1) {
    currentImage = freezeImage;
  }

  PImage textureImage = buffer[currentImage];

  if (colorSetting == 0) {
    background(0);
    tint(0, 0, 255, 255);
    gray = grays[currentImage];
    /*beginShape();
     texture(gray);
     vertex(ks[0],ks[1],0,0);
     vertex(displayWidth+ks[2],ks[3],gray.width,0);
     vertex(displayWidth+ks[4],displayHeight+ks[5],gray.width,gray.height);
     vertex(ks[6],displayHeight+ks[7],0,gray.height);
     endShape();*/
    tint(0, 0, 255, imageSaturation);
  } 
  else if (colorSetting == 1) {

    float milli = millis();
    float milliNoise = noise(milli*.0001) * 2 * (noise(milli) - .5);

    tintHue = (int)(abs(milliNoise) * 2 * 360.0);
    if (random(0, 2) < 1) { 
      tint(tintHue, imageSaturation, 255);
    } 
    else {
      tint(0, 0, 255);
    }

    textureImage = grays[currentImage];
  } 
  else if (colorSetting == 2) {
    tint(tintHue, 0, 255);
    textureImage = grays[currentImage];
  }

  drawTexture(textureImage, 0);

  if (doubleMode) {
    drawTexture(textureImage, imageWidth);
  }

  currentImage++;
  if (currentImage >= bufferSize) {
    currentImage = 0;
  }

  if (statusCount > 0) {
    statusCount-= (10.0 / frameSpeed);
    if (verbose || statusMessage == "Verbose off") {
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

void keyPressed() {

  if (recording) {
    if (key == 'r') {
      recording = false;
      if (step != 0) {
        playback = true;
      }
      setStatus("");
    }
    return;
  }

  if (newSearch) {
    if (keyCode == ENTER) {
      if (searchString.length() > 0) {
        searches.add(searchString);
        currentSearch = searches.size() - 1;
        fillBuffer();
      }
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
  }

  if (key == 'v') {
    verbose = !verbose;
    if (verbose) setStatus("Verbose on");
    else setStatus("Verbose off");
  }

  if (key == ' ') {
    setStatus("Next"); 
    currentSearch++;// = (int)random(0, searches.size()-1);
    println("Searching " + currentSearch);
    if (currentSearch >= searches.size()) {
      currentSearch = 0;
    }
    updateSearches();
    fillBuffer();
  }

  if (key == '6') {
    setStatus("Next"); 
    currentSearch++;

    if (currentSearch >= searches.size()) {
      currentSearch = 0;
    }
    updateSearches();
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

  if (key == 'c') {
    colorSetting++;
    if (colorSetting > 1) colorSetting = 0;
    if (colorSetting == 0) setStatus("Color"); 
    if (colorSetting == 1) setStatus("Hue Shifter"); 
    if (colorSetting == 2) setStatus("Grayscale");
  }

  if (key == 'r') {
    randomness = !randomness;
    if (randomness) setStatus("Random"); 
    if (!randomness) setStatus("Normal");
  }

  if (key == 'p') {
    playback = !playback;
    setStatus("Playback: " + playback);
  }

  if (key == 's') {
    newSearch = true;
    searchString = "";
    setStatus("Search: ", true);
  }

  if (key == 'r') {
    recording = true;
    sequence = new int[maxSequenceLength];
    step = 0;
    setStatus("Recording", true);
  }

  if (key == 'd') {
    doubleMode = !doubleMode;
    setStatus("Double: " + doubleMode);
  }
}




void doRandomStuff(boolean force) {

  if (!randomness) return;

  int elapsed = millis() - lastTime;  

  if (randomDelay != 0 && elapsed > randomDelay) {
    lastTime = millis(); 

    currentSearch = (int)random(0, searches.size()-1);
    if (currentSearch >= searches.size()) {
      currentSearch = 0;
    }
    updateSearches();
    fillBuffer(); 

    colorSetting = 1;

    frameSpeed = (int) random(15, 50);
    frameRate(frameSpeed);
    if (verbose) setStatus("FPS " + frameSpeed);
  }
  float longDelayChance = .0025;
  if (longDelayChance > 0 && random(1.0)/longDelayChance < 1) {
    delay(int(random(1000, 3000)));
  }
}



void loadCachedSearches() {
  File file = new File(sketchPath + "/cache");
  if (file.isDirectory()) {
    String names[] = file.list();
    for (int i = 0; i < names.length; i++) {
      if (!names[i].substring(0, 1).equals(".")) {
        searches.add(names[i]);
      }
    }
  } 
  println(searches);
}


void updateSearches() {

  if (local) return;
  String searchLines[] = loadStrings(baseURL + "list.php");

  if (searchLines.length == searches.size()) return;
  searches = new ArrayList();
  for (int i = 0; i < searchLines.length; i++) {
    searches.add(searchLines[i]);
  }        
  currentSearch = 0;
}


void fillBuffer() {
  attempt = 0;
  lines = null;
  lastBuffer = 0;
  filling = true;
}


int lastBuffer = 0;
String lines[];

void updateBuffer() {

  if (lastBuffer >= 30) {
    lastBuffer = 0;
    filling = false; 
    ready = true;
  }  

  if (!filling) return;

  while (true) {
    attempt++;
    String fname = "cache/" + searches.get(currentSearch) + "/" + lastBuffer + ".jpg";
    PImage img = loadImage(fname);
    if (img != null) {

      float aspect;
      int displayWidth;
      int displayHeight;
      aspect = (float)img.width/(float)img.height;
      displayWidth = (int)(aspect * (float)img.height);
      displayHeight = img.height;

      if (displayWidth > img.width) {
        displayWidth = img.width;
        displayHeight =(int)((float)img.height/aspect);
      }

      float newAspect = (float)displayWidth / (float)displayHeight;
      int newW = (int)((float)height * aspect);
      float startX = (imageWidth-newW) / 2.0;
      PImage padImage = new PImage(imageWidth, height);
      padImage.copy(img, 0, 0, img.width, img.height, (int)startX, 0, newW, height);

      buffer[lastBuffer] = padImage;

      PImage cp = padImage.get();
      cp.filter(GRAY);
      grays[lastBuffer] = cp;

      println("Found " + fname);
      lastBuffer++;
      return;
    }

    //if ((attempt %4) == 0 || lines == null) {
    //  int start = attempt;
    //  lines = loadStrings(baseURL + "index.php?query=" + searches.get(currentSearch) + "&start=" + start);
    //}

    PGraphics pg;
    int i = lastBuffer % 4;

    fname = "cache/" + searches.get(currentSearch) + "/" + lastBuffer + ".jpg";
    img = loadImage(lines[i]);   

    if (img != null && img.width > 0 && img.height > 0) {
      pg = createGraphics(img.width, img.height, P3D);
      pg.beginDraw();
      pg.background(255);
      pg.image(img, 0, 0, img.width, img.height); 
      pg.endDraw();
      pg.save(fname);
      buffer[lastBuffer] = img;
      lastBuffer++;
      return;
    }
  }
}



void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);

  freezeImage = pitch % buffers.length;

  if (recording) {
    sequence[step] = freezeImage;
    step++;
    sequenceLength = step;
    println(sequence);
  }
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
}

void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  println();
  println("Controller Change:");
  println("--------");
  println("Channel:"+channel);
  println("Number:"+number);
  println("Value:"+value);
  if (number == 1) {
    frameSpeed = value / 2+ 1;
    frameRate(frameSpeed);
    setStatus("FPS " + frameSpeed);
  } 
  else if (number == 7) {
    imageSaturation = value * 2;
  }
}

