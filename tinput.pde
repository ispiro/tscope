import themidibus.*;
import processing.core.PApplet;

class TInput {
  MidiBus myBus;
  TOptions t;
  int[] midiOverrides = new int[10];
  PrintWriter output;
  TInput(processing.core.PApplet parent, TOptions options) {
    this.t = options;
    myBus = new MidiBus(parent, 0, 1);
    
     output = createWriter("save.txt"); 
    
    
  }



  int controlId = 0;

  void keyPressed(char k, int c) {

    
    if (c == LEFT) {
      controlId--;
      if (controlId < 0) controlId = t.midiMap.length - 1;
      int midiValue = midiOverrides[controlId];
      setStatus(t.midiMap[controlId][0] + " " + midiValue);
    }
        
    if (c == RIGHT) {
      controlId++;
      if (controlId >= t.midiMap.length) controlId = 0;
      int midiValue = midiOverrides[controlId];
      setStatus(t.midiMap[controlId][0] + " " + midiValue);
    }
    
    if (c == DOWN) {
      if (midiOverrides[controlId] > 0) midiOverrides[controlId]--;
      int midiValue = midiOverrides[controlId];
      int midiId = t.mm.get(t.midiMap[controlId][0]);
      controllerChange(0, midiId, midiValue);
      //setStatus(t.midiMap[controlId][0] + " " + midiValue);
    }
        
    if (c == UP) {
      if (midiOverrides[controlId] < 255) midiOverrides[controlId]++;
      int midiValue = midiOverrides[controlId];
      int midiId = t.mm.get(t.midiMap[controlId][0]);
      controllerChange(0, midiId, midiValue);
    }
           
        
    if (key == 'v') {
    t.verbose = !t.verbose;
    if (t.verbose) setStatus("Verbose on");
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
    if (t.frameSpeed < 90) {
      t.frameSpeed = t.frameSpeed + 1;
      frameRate(t.frameSpeed);
      setStatus("FPS " + t.frameSpeed);
    }
  }

  if (key == '-') {
    ready = true;
    if (t.frameSpeed > 1) {
      t.frameSpeed = t.frameSpeed - 1;
      frameRate(t.frameSpeed);
      setStatus("FPS " + t.frameSpeed);
    }
  }
  int k2[];
  if (key == 'k') {
    t.kernelSize+=2;
    if (t.kernelSize > 7) {
      t.kernelSize = 1;
    }
   
    setStatus("Blur " + t.kernelSize);

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



    /******************* MIDI SUPPORT *******************/

    void noteOn(int channel, int pitch, int velocity) {
      // Receive a noteOn
     if (pitch == 119) {
       output.println("   " + searches.get(currentSearch));
        output.flush();
     } 
     
     if (pitch == 120) {
       output.println("*  " + searches.get(currentSearch));
      output.flush();  
   }

      //freezeImage = pitch % buffer.length;
      //t.opacity = (int)(velocity * 2);
      //if (t.opacity > 255) t.opacity = 255;
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
      if (number == t.mm.get("FPS")) {
        t.frameSpeed = (int)(value * .66) + 1;
        updateSpeed = true;
        setStatus("FPS " + t.frameSpeed);
      } 
      else if (number == t.mm.get("Sat")) {
        t.imageSaturation = (256- (value * 2));
        setStatus("Sat " + (value * 2));
      } 
      else if (number == t.mm.get("Lum")) {
        t.brightness = value * 2;
        setStatus("Lum " + t.brightness);
      }  
      else if (number == t.mm.get("Tin")) {
        t.tintAmount = value * 2;
        setStatus("Tin " + t.tintAmount);
      } 
      else if (number == t.mm.get("Hue")) {
        t.tintHue = value * 2;
        setStatus("Hue " + t.tintHue);
      } 
      else if (number == t.mm.get("Len")) {
        t.loopSize = 1 + (int) (value  / 4);
        setStatus("Len " + t.loopSize);
      } 
      else if (number == 1) {    
        t.randomDelay = 0;
        if (value != 0) t.randomDelay = (15000 - (value * 100));
        setStatus("Rnd " + value);
      } 
      else if (number == t.mm.get("Off")) {
        t.bufferOffset = (int) (value  / 4);
        setStatus("Off " + t.bufferOffset);
      }
      else if (number == t.mm.get("Seq")) {
        currentSearch = value;
        fillBuffer();
        search = (String)searches.get(currentSearch);
        if (search.length() > 13) {
          setStatus(search.substring(0, 10) + "...");
        } 
        else {
          setStatus(search);
        }
      }
      else if (number == 10) {
        currentSearch = 128 + value;
        if (currentSearch >= searches.size()) currentSearch = searches.size() - 1;
        fillBuffer();
        search = (String)searches.get(currentSearch);
        if (search.length() > 13) {
          setStatus(search.substring(0, 10) + "...");
        } 
        else {
          setStatus(search);
        }
      }
    }
  }

