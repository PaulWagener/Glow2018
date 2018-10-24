boolean debug = true;


Kinect2 kinect = new Kinect2();

void settings() {
  size(1024, 740, P3D);
}


void setup() {
  kinect = new Kinect2(this);
  kinect.initDepth();
  kinect.initDevice();
}

/**
 * Loads data from the Kinect into the depthData Mat,
 * and normalizes it between 0.0 and 1.0
 */
void refreshDepthData() {
  if(kinect2.getNumKinects() > 0) {
    // Use the real Kinect data
    kinect.getRawDepth(); // TODO
  } else {
    // No Kinect attached, create a simulation of depth data
  }
}


void draw() {
  background(0);
  
  // Choose bet
  kinect2.printDevices();
  
  if(debug) {
    drawDebug();
  }
}

void drawDebug() {
  // Draw the Kinect data in the top-left
}
