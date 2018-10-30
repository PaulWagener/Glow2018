boolean debug = true;

import org.openkinect.processing.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import processing.video.Capture;

DwOpticalFlow opticalflow;
Kinect2 kinect = new Kinect2(this);
Capture cam;
PGraphics2D cam_graphics;

void settings() {
  size(1024, 740, P3D);
}


void setup() {
  kinect = new Kinect2(this);
  kinect.initDepth();
  kinect.initDevice();
  
  // Just for testing
  cam = new Capture(this, 640, 480, 30);
  cam.start();
  
  cam_graphics = (PGraphics2D)createGraphics(640, 480, P2D);
}

/**
 * Loads data from the Kinect into the depthData Mat,
 * and normalizes it between 0.0 and 1.0
 */
void refreshDepthData() {
  if(kinect.getNumKinects() > 0) {
    // Use the real Kinect data
    kinect.getRawDepth(); // TODO
  } else {
    // No Kinect attached, create a simulation of depth data
  }
}


void draw() {
  
  background(0);
  
  if(cam.available()) {
    cam.read();
    cam_graphics.beginDraw();
    cam_graphics.background(0);
    cam_graphics.image(cam, 0, 0);
    cam_graphics.endDraw();
  }
  
  image(cam_graphics, 0, 0, 1024, 740);
  
  // Choose bet
  //kinect.printDevices();
  
  if(debug) {
    drawDebug();
  }
}

void drawDebug() {
  // Draw the Kinect data in the top-left
}
