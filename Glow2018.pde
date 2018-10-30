boolean debug = true;

import org.openkinect.processing.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import processing.video.Capture;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;

DwOpticalFlow opticalflow;
Kinect2 kinect = new Kinect2(this);
Capture cam;
PGraphics2D cam_graphics, flow_graphics;
DwFluid2D.FluidData fluid_data;
DwFluid2D fluid;
DwPixelFlow context;

void settings() {
  size(1024, 740, P3D);
}

class MyFluidData implements DwFluid2D.FluidData {
    @Override
    // this is called during the fluid-simulation update step.
    public void update(DwFluid2D fluid) {
      fluid.addVelocity(20, 30, 50, 1.1, 2.2);
    }
}

void setup() {
  kinect = new Kinect2(this);
  kinect.initDepth();
  kinect.initDevice();
  
  // Just for testing
  cam = new Capture(this, 640, 480, 30);
  cam.start();
  
  cam_graphics = (PGraphics2D)createGraphics(640, 480, P2D);
  flow_graphics = (PGraphics2D)createGraphics(1024, 740, P2D);
  
  context = new DwPixelFlow(this);
  context.print();
  context.printGL();
    
  // Setup fluid simulation
  fluid_data = new MyFluidData();
  fluid = new DwFluid2D(context, 1024, 740, 1);
    
  // some fluid parameters
  fluid.param.dissipation_density     = 0.90f;
  fluid.param.dissipation_velocity    = 0.80f;
  fluid.param.dissipation_temperature = 0.70f;
  fluid.param.vorticity               = 0.30f;
  
  opticalflow = new DwOpticalFlow(context, 640, 480);
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
  
  
  flow_graphics.beginDraw();
  flow_graphics.background(0);
  flow_graphics.endDraw();
  opticalflow.renderVelocityShading(flow_graphics);
  
  image(flow_graphics, 0, 0, 1024, 740);
  
  opticalflow.update(cam_graphics);
  // Choose bet
  //kinect.printDevices();
  
  if(debug) {
    drawDebug();
  }
}

void drawDebug() {
  // Draw the Kinect data in the top-left
}
