boolean debug = false;

import org.openkinect.processing.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import processing.video.Capture;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;

DwOpticalFlow opticalflow;
Kinect2 kinect = new Kinect2(this);
DwGLSLProgram shaderVelocity, shaderDensity;
DwFluid2D fluid;
DwPixelFlow context;

// Source graphics (Kinect depth data)
final int sourceWidth = 512, sourceHeight = 512;
PGraphics2D sourceGraphics;

// Optical flow velocity
final int flowWidth = 200, flowHeight = 200;
PGraphics2D flowGraphics; 

// Fluid
final int fluidWidth = 480, fluidHeight = 320;
PGraphics2D fluidGraphics;

void settings() {
  size(1200, 1000, P3D);
}

class MyFluidData implements DwFluid2D.FluidData {
  @Override
  // this is called during the fluid-simulation update step.
  public void update(DwFluid2D fluid) {
    float px = random(fluidWidth);
    float py = random(fluidHeight);
    fluid.addDensity (px, py, 15, 1.0f, 0.0f, 0.40f, 1f, 1);
  }
}
 int[] tempArray = new int[1];
 
void setup() {
  kinect = new Kinect2(this);
  kinect.initDepth();
  kinect.initDevice();
  
  context = new DwPixelFlow(this);
  
  // Set up source data
  sourceGraphics = (PGraphics2D)createGraphics(sourceWidth, sourceHeight, P2D); //<>//
  
  // Set up optical flow
  opticalflow = new DwOpticalFlow(context, flowWidth, flowHeight);
  
  flowGraphics = (PGraphics2D)createGraphics(flowWidth, flowHeight, P2D);
    
  // Setup fluid simulation
  fluid = new DwFluid2D(context, fluidWidth, fluidHeight, 1);
  fluid.param.dissipation_density     = 1.0f;
  fluid.param.dissipation_velocity    = 0.9f;
  fluid.param.vorticity               = 0.4f;
  shaderVelocity = context.createShader("addVelocity.frag");
  shaderDensity = context.createShader("addDensity.frag");
  fluidGraphics = (PGraphics2D)createGraphics(fluidWidth, fluidHeight, P2D);
}

void draw() {  
  if(kinect.getNumKinects() > 0) {
    // Use the real Kinect data
    kinect.getRawDepth(); // TODO
  } else {
    if(millis() > 3000) {
      sourceGraphics.beginDraw();
      sourceGraphics.background(0);
      //sourceGraphics.image(cam, 0, 0, sourceWidth, sourceHeight);
      float x = sourceWidth / 2 + sin(millis() / 3800.0) * sourceWidth / 3;
      float y = sourceWidth / 2 + cos(millis() / 3600.0) * sourceWidth / 4;
      sourceGraphics.ellipse(x, y, 90, 90);
      float x2 = sourceWidth / 2 + sin(millis() / 1900.0) * sourceWidth / 3;
      float y2 = sourceWidth / 2 + cos(millis() / 500.0) * sourceWidth / 4;
      sourceGraphics.ellipse(x2, y2, 100, 100);
      sourceGraphics.endDraw();
    }
  }
  
  // Update optical flow
  opticalflow.update(sourceGraphics);  
  flowGraphics.beginDraw();
  flowGraphics.background(0);
  flowGraphics.endDraw();
  opticalflow.renderVelocityShading(flowGraphics);

  
  // Update fluid velocity from optical flow
  context.begin();
  context.beginDraw(fluid.tex_velocity.dst);
  shaderVelocity.begin();
  shaderVelocity.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);                                                                   
  shaderVelocity.uniformTexture("tex_opticalflow", opticalflow.frameCurr.velocity);
  shaderVelocity.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
  shaderVelocity.drawFullScreenQuad();
  shaderVelocity.end();
  context.endDraw();
  context.end();
  fluid.tex_velocity.swap();
  
  // Add density to fluid
  colorMode(HSB, 255);
  color c = color((millis() / 1000.0f * 255.0) % 255.0f, 255, 255);
  
  context.begin(); //<>//
  context.getGLTextureHandle(sourceGraphics, tempArray);
  int sourceGraphicsGL = tempArray[0];
  context.beginDraw(fluid.tex_density.dst);
  shaderDensity.begin();
  shaderDensity.uniform1f("time", (millis() / 1000.0f) % 1.0f);
  shaderDensity.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);
  //shaderDensity.uniform3f("color", red(c) / 255.0, green(c) / 255.0, blue(c) / 255.0);
  shaderDensity.uniformTexture("texture_old", fluid.tex_density.src);
  shaderDensity.uniformTexture("texture_new", sourceGraphicsGL);
  shaderDensity.drawFullScreenQuad();
  shaderDensity.end();
  context.endDraw();
  context.end();
  fluid.tex_density.swap();  
  fluid.update(); //<>//
  

  fluid.renderFluidTextures(fluidGraphics, 0);
  
  image(fluidGraphics, 0, 0, width, height);

  if(debug) {
    drawDebug();
  }
}

void drawDebug() {
  // Draw the Kinect data in the top-left
  int debugWindow = 0;
  drawGraphics(sourceGraphics, debugWindow++);
  drawGraphics(flowGraphics, debugWindow++);
  drawGraphics(fluidGraphics, debugWindow++);
}

void drawGraphics(PGraphics graphics, int window) {
  final int debugWidth = 400, debugHeight = 300;
  image(graphics, 10+(debugWidth+10)*window, 10, debugWidth, debugHeight);
}

color hsv2rgb(float hue, float saturation, float value) {
    int h = (int)(hue * 6);
    float f = hue * 6 - h;
    float p = value * (1 - saturation);
    float q = value * (1 - f * saturation);
    float t = value * (1 - (1 - f) * saturation);

    
    switch (h) {
      case 0: return color(value * 255, t * 255, p * 255);
      case 1: return color(q * 255, value * 255, p * 255);
      case 2: return color(p * 255, value * 255, t * 255);
      case 3: return color(p * 255, q * 255, value * 255);
      case 4: return color(t * 255, p * 255, value * 255);
      case 5: return color(value * 255, p * 255, q * 255);
      default: throw new RuntimeException("Something went wrong when converting from HSV to RGB. Input was " + hue + ", " + saturation + ", " + value);
  }
}
