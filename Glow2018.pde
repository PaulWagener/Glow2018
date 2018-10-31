boolean debug = true;

import org.openkinect.processing.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import processing.video.Capture;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;

DwOpticalFlow opticalflow;
Kinect2 kinect = new Kinect2(this);
Capture cam;
PGraphics2D cam_graphics, flow_graphics;
DwFluid2D.FluidData fluid_data;
DwFluid2D fluid;
DwPixelFlow context;

final int simWidth = 480;
final int simHeight = 320;

final int fluidWidth = 480;
final int fluidHeight = 320;

void settings() {
  size(1024, 740, P3D);
}

class MyFluidData implements DwFluid2D.FluidData {
    @Override
    // this is called during the fluid-simulation update step.
    public void update(DwFluid2D fluid) {
      fluid.addVelocity(20, 30, 50, 1.1, 2.2);
      
      float px = random(fluidWidth);
      float py = random(fluidHeight);
      fluid.addDensity (px, py, 15, 1.0f, 0.0f, 0.40f, 1f, 1);
      
    }
}

void setup() {
  kinect = new Kinect2(this);
  kinect.initDepth();
  kinect.initDevice();
  
  // Just for testing
  cam = new Capture(this, simWidth, simHeight, 30);
  cam.start();
  
  cam_graphics = (PGraphics2D)createGraphics(simWidth, simWidth, P2D);
  flow_graphics = (PGraphics2D)createGraphics(1024, 740, P2D);
  
  context = new DwPixelFlow(this);
  context.print();
  context.printGL();
    
  // Setup fluid simulation
 
  fluid = new DwFluid2D(context, fluidWidth, fluidHeight, 1);
  fluid_data = new MyFluidData();
  fluid.addCallback_FluiData(fluid_data);
    
  // some fluid parameters
  fluid.param.dissipation_density     = 0.90f;
  fluid.param.dissipation_velocity    = 0.80f;
  fluid.param.dissipation_temperature = 0.70f;
  fluid.param.vorticity               = 0.30f;
  
  opticalflow = new DwOpticalFlow(context, simWidth, simHeight);
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
  
  // Add optical flow velocity to fluid simulation
  context.begin();
  context.beginDraw(fluid.tex_velocity.dst);
  DwGLSLProgram shader = context.createShader("data/addVelocity.frag");
  shader.begin();
  shader.uniform2f     ("wh"             , fluid.fluid_w, fluid.fluid_h);                                                                   
  shader.uniform1i     ("blend_mode"     , 2);    
  shader.uniform1f     ("multiplier"     , 1.0f);   
  shader.uniform1f     ("mix_value"      , 0.1f);
  shader.uniformTexture("tex_opticalflow", opticalflow.frameCurr.velocity);
  shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
  shader.drawFullScreenQuad();
  shader.end();
  context.endDraw();
  context.end("app.addDensityTexture");
  
  fluid.tex_velocity.swap(); 
  // Update fluid simulation
  fluid.update();
  background(0);
  opticalflow.update(cam_graphics);
  //opticalflow.renderVelocityShading(flow_graphics);
  // opticalflow.renderVelocityStreams(flow_graphics, 6);
  fluid.renderFluidTextures(flow_graphics, 0);
  
  
  image(flow_graphics, 0, 0, 1024, 740);
  
  
  // Choose bet
  //kinect.printDevices();
  
  if(debug) {
    drawDebug();
  }
}

void drawDebug() {
  // Draw the Kinect data in the top-left
}
