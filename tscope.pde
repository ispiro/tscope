/**
 * Tachistoscope
 * ispiro
 */
import processing.opengl.*;
import java.util.Map;

/******************* GLOBALS *******************/

int currentSearch = 30;
int currentImage = 0;
int count = 0;
int freezeImage = -1;
int attempt = 0;
int lastTime;
int lastBuffer = 0;
int nextSet = -1;
int previewWidth;

String statusMessage;
String searchString;
String search;

float statusCount = 0;
float randomFrame;

boolean newSearch;
boolean updateSpeed = true;
boolean ready = false;
boolean filling = false;

HashMap<String, String[]> images;
ArrayList searches;
PFont font;
PImage buffer[] = new PImage[100];
PImage grays[] = new PImage[100];

TOptions t;
TInput in;

/******************* SETUP *******************/

void setup() {
  
  t = new TOptions();
  in = new TInput(this, t);  

  loadCachedSearches();
  lastTime = millis();
  int windowWidth = t.width;
  if (t.doubleMode) {
    previewWidth = (int)(t.width * t.previewScale);
    windowWidth = t.width + previewWidth;
  }
  size((int)(windowWidth), (int)(t.height), OPENGL);
  if (t.doubleMode) {
    frame.setLocation(t.masterWidth-previewWidth, -20);
  }
  colorMode(HSB);
  frameRate(100);
  
  font = loadFont("CourierNew36.vlw"); 
  textFont(font, 32); 
  fillBuffer();
}




void drawTexture(PImage img) {
  float displayWidth;
  float displayHeight;
  float aspect = (float)img.width/(float) img.height;
  displayWidth = aspect * height;
  displayHeight = height;

  if (displayWidth > t.width) {
    displayWidth = t.width;
  }

  if (t.doubleMode) {
    int startX = (int)(t.width*t.previewScale) + abs((int)((displayWidth - t.width) / 2));   
    image(img, startX, 0, displayWidth, displayHeight);
    
    startX = (int)((t.width*t.previewScale - displayWidth*t.previewScale) / 2);
    image(img, startX, 0, displayWidth * t.previewScale, displayHeight*t.previewScale);
  } 
  else {
    int startX = (int)((t.width - displayWidth) / 2);
    image(img, startX, 0, displayWidth, displayHeight);
  }
}


void draw() {

  updateBuffer();
  background(0);

  if (!ready) return;
  
  if (updateSpeed) {
    frameRate(t.frameSpeed);
    updateSpeed = false;
  }


  int theTint = t.tintHue;
  if (t.tintHue == 0) {
    float milli = millis();
    float milliNoise = noise(milli*.0001) * 2 * (noise(milli) - .5); 
    theTint = (int)(abs(milliNoise) * 2 * 360.0);
  }

 
  if (freezeImage != -1) {  
    tint(theTint, t.tintAmount, t.brightness);
    drawTexture(buffer[freezeImage]);
    tint(theTint, t.tintAmount, t.brightness, t.imageSaturation);
    drawTexture(grays[freezeImage]);

  } else {
    if (t.kernelSize == 1) {
      tint(theTint, t.tintAmount, t.brightness);
      drawTexture(buffer[currentImage]);
      tint(theTint, t.tintAmount, t.brightness, t.imageSaturation);
      drawTexture(grays[currentImage]);
    } else {
      
      
    for (int d = 0; d < t.kernelSize; d++) {
    
      int pos = currentImage + d;
      while (pos >= t.bufferSize) {
        pos -= t.bufferSize;
      }

      //tint(theTint, t.tintAmount, t.brightness, t.kernel[d]);
      //drawTexture(buffer[pos]);
      tint(theTint, t.tintAmount, t.brightness, t.kernel[d]);
      drawTexture(grays[pos]);
    
    }
  }
  }
  count++;
  currentImage = count + t.bufferOffset;

  currentImage = t.bufferOffset + ((count + t.bufferOffset) % t.loopSize);
  while (currentImage >= t.bufferSize) {
    currentImage -= t.bufferSize;
  }

  if (statusCount > 0) {
    statusCount-= (10.0 / t.frameSpeed);
    if (t.verbose || statusMessage == "t.verbose off") {
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
  
  in.keyPressed(key, keyCode);
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
    t.bufferSize = ims.length;
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
  t.bufferSize = 32;
}

