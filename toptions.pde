class TOptions {

  int width =            1280;
  int height =           740;
  int masterWidth =      1680;
  boolean doubleMode =   false;
  float previewScale =   0.25;
  int randomDelay =      0;
  int frameSpeed =       10;
  int brightness =       100;
  int opacity =          1;
  int imageSaturation =  255;
  int bufferSize =       30;
  int loopSize =         30;
  int bufferOffset =     0;
  int tintHue =          0;
  int tintAmount =       0;
  int kernelSize =       1;
  int[] kernel =         {200, 160, 140, 120, 100, 80, 60};
  boolean verbose =      true;
  boolean randomness =   false;

  String[][] midiMap = { {"FPS",  "7"   },
                         {"Sat",  "73"  },
                         {"Lum",  "71"  },
                         {"Tin",  "72"  },
                         {"Hue",  "74"  },
                         {"Len",  "5"   },
                         {"Off",  "84"  },
                         {"Seq",  "93"  }  };

  Map<String, Integer> mm;
  
  TOptions() {
    mm = new HashMap<String, Integer>();
    for (int i = 0; i < midiMap.length; i++) {
      mm.put(midiMap[i][0], Integer.parseInt(midiMap[i][1]));
    }
    
  }
 
}
