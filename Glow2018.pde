boolean debug = true;

boolean paused = false;

import org.openkinect.processing.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import processing.video.Capture;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluidParticleSystem2D;

DwOpticalFlow opticalflow;
Kinect kinect = new Kinect(this);
DwGLSLProgram shaderVelocity, shaderDensity, shaderParticles, shaderParticlesRender;
DwFluid2D fluid;
DwPixelFlow context;
DwFluidParticleSystem2D particleSystem = new DwFluidParticleSystem2D();

int kinectThresholdNear = 10;
int kinectThresholdFar = 20;

PGraphics2D glowGraphics;

// Source graphics (Kinect depth data)
final int sourceWidth = 512, sourceHeight = 512;
PGraphics2D sourceGraphics;

// Optical flow velocity
final int flowWidth = 200, flowHeight = 200;
PGraphics2D flowGraphics; 

// Fluid
final int fluidWidth = 800, fluidHeight = 600;
PGraphics2D fluidGraphics;

void settings() {
  size(1200, 900, P3D);
}

 int[] tempArray = new int[1];
 
void setup() {
  kinect.initDepth();
  context = new DwPixelFlow(this);
  
  PImage glowImage = loadImage("glow.png"); 
  glowGraphics = (PGraphics2D)createGraphics(glowImage.width, glowImage.height, P2D);
  glowGraphics.beginDraw();
  glowGraphics.image(glowImage, 0, 0);
  glowGraphics.endDraw();
  
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
  fluid.param.num_jacobi_projection   = 6;
  shaderVelocity = context.createShader("addVelocity.frag");
  shaderDensity = context.createShader("addDensity.frag");
  fluidGraphics = (PGraphics2D)createGraphics(fluidWidth, fluidHeight, P2D);
  
  // Particles
  particleSystem.resize(context, fluidWidth, fluidHeight);
  shaderParticles  = context.createShader("particles.frag");
  shaderParticlesRender = context.createShader("particleRender.glsl", "particleRender.glsl");
  shaderParticlesRender.vert.setDefine("SHADER_VERT", 1);
  shaderParticlesRender.frag.setDefine("SHADER_FRAG", 1);
}

void draw() {
  background(0);
  if(kinect.numDevices() > 0) {
    sourceGraphics = (PGraphics2D)kinect.getDepthImage();
    // TODO: Threshold
    
  } else {
    if(millis() > 3000) {
      float millis = millis();
      sourceGraphics.beginDraw();
      sourceGraphics.background(0);
      if(!paused) {
        float x = sourceWidth / 2 + sin(millis / 3800.0) * sourceWidth / 3;
        float y = sourceWidth / 2 + cos(millis / 3600.0) * sourceWidth / 4;
        sourceGraphics.ellipse(x, y, 90, 90);
        float x2 = sourceWidth / 2 + sin(millis / 1900.0) * sourceWidth / 3;
        float y2 = sourceWidth / 2 + cos(millis / 500.0) * sourceWidth / 4;
        sourceGraphics.ellipse(x2, y2, 100, 100);
      }
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
  context.end(); //<>//
  fluid.tex_velocity.swap();
  
  // Add density to fluid  
  context.begin(); //<>//
  int textureNew = getGL(sourceGraphics);
  context.beginDraw(fluid.tex_density.dst);
  shaderDensity.begin();
  shaderDensity.uniform1f("time", (millis() / 500.0f) % 1.0f);
  shaderDensity.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);
  shaderDensity.uniformTexture("texture_old", fluid.tex_density.src);
  shaderDensity.uniformTexture("texture_new", textureNew);
  shaderDensity.drawFullScreenQuad(); //<>//
  shaderDensity.end();
  context.endDraw();
  context.end();
  fluid.tex_density.swap();  
  fluid.update();
  
  // Update particles
  particleSystem.update(fluid);
  
  context.begin();
  context.beginDraw(particleSystem.tex_particles.dst);
  shaderParticles.begin();
  shaderParticles.uniform2f("wh_particles", particleSystem.particles_x, particleSystem.particles_y);
  shaderParticles.uniformTexture("tex_particles", particleSystem.tex_particles.src);
  shaderParticles.drawFullScreenQuad();
  shaderParticles.end();
  context.endDraw();
  context.end("ParticleSystem.update");
  
  particleSystem.tex_particles.swap();
  
  // Draw fluid
  fluid.renderFluidTextures(fluidGraphics, 0);
  
  // Overlay particles
  
  
  context.begin();
  int textureGlow = getGL(glowGraphics);
  fluidGraphics.beginDraw();
  fluidGraphics.blendMode(PConstants.BLEND);
  shaderParticlesRender.begin();
  shaderParticlesRender.uniform2i     ("num_particles", particleSystem.particles_x, particleSystem.particles_y);
  shaderParticlesRender.uniformTexture("tex_particles", particleSystem.tex_particles.src);
  shaderParticlesRender.uniformTexture("tex_glow", textureGlow);
  shaderParticlesRender.drawFullScreenPoints(particleSystem.particles_x * particleSystem.particles_y);
  shaderParticlesRender.end();
  fluidGraphics.endDraw();
  context.end("ParticleSystem.render");
  
  image(fluidGraphics, 0, 0, width, height);

  if(debug) {
    drawDebug();
  }
}

int getGL(PGraphics2D g) {
  context.getGLTextureHandle(g, tempArray);
  return tempArray[0];
}

void drawDebug() {
  // Draw the Kinect data in the top-left
  int debugWindow = 0;
  drawGraphics(sourceGraphics, debugWindow++);
  drawGraphics(flowGraphics, debugWindow++);
  drawGraphics(glowGraphics, debugWindow++);
  drawGraphics(fluidGraphics, debugWindow++);
  
  // Debug values
  text("Kinect Threshold Near: " + kinectThresholdNear, 20, 325);
  text("Kinect Threshold Far: " + kinectThresholdFar, 20, 340);
}

public void keyReleased(){
  if(key == '+') kinectThresholdFar += 10;
  if(key == '_') kinectThresholdFar -= 10;
  if(key == '=') kinectThresholdNear += 10;
  if(key == '-') kinectThresholdNear -= 10;
  if(key == 'p') paused = !paused;
}

void drawGraphics(PGraphics graphics, int window) {
  final int debugWidth = 100, debugHeight = 100;
  image(graphics, 10+(debugWidth+10)*window, 10, debugWidth, debugHeight);
}
