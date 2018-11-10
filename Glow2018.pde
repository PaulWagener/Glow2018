boolean debug = false;

import org.openkinect.processing.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import processing.video.Capture;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluidParticleSystem2D;

DwOpticalFlow opticalflow;
Kinect2 kinect = new Kinect2(this);
DwGLSLProgram shaderVelocity, shaderDensity, shaderParticles, shaderParticlesRender;
DwFluid2D fluid;
MyFluidData fluidData = new MyFluidData();
DwPixelFlow context;
DwFluidParticleSystem2D particleSystem = new DwFluidParticleSystem2D();


// Source graphics (Kinect depth data)
final int sourceWidth = 512, sourceHeight = 512;
PGraphics2D sourceGraphics;

// Optical flow velocity
final int flowWidth = 200, flowHeight = 200;
PGraphics2D flowGraphics; 

// Fluid
final int fluidWidth = 480, fluidHeight = 320;
PGraphics2D fluidGraphics;
PGraphics2D obstacleGraphics;

void settings() {
  size(800, 600, P3D);
}

class MyFluidData implements DwFluid2D.FluidData {
  @Override
  // this is called during the fluid-simulation update step.
  public void update(DwFluid2D fluid) {
    float px = random(fluidWidth);
    float py = random(fluidHeight);
    // fluid.addDensity (px, py, 5, 0.0f, 0.0f, 0.90f, 1f, 1);
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
  fluid.addCallback_FluiData(fluidData);
  shaderVelocity = context.createShader("addVelocity.frag");
  shaderDensity = context.createShader("addDensity.frag");
  fluidGraphics = (PGraphics2D)createGraphics(fluidWidth, fluidHeight, P2D);
  
  // Particles
  particleSystem.resize(context, fluidWidth, fluidHeight);
  shaderParticles  = context.createShader("particles.frag");
  shaderParticlesRender = context.createShader("particleRender.glsl", "particleRender.glsl");
  shaderParticlesRender.vert.setDefine("SHADER_VERT", 1);
  shaderParticlesRender.frag.setDefine("SHADER_FRAG", 1);
  
  // Obstacles (border)
  obstacleGraphics = (PGraphics2D)createGraphics(fluidWidth, fluidHeight, P2D);
  obstacleGraphics.beginDraw();
  obstacleGraphics.clear();
  obstacleGraphics.strokeWeight(10);
  obstacleGraphics.stroke(0);
  
  obstacleGraphics.noFill();
  obstacleGraphics.rect(0, 0, obstacleGraphics.width, obstacleGraphics.height);
  obstacleGraphics.endDraw();
  
  //fluid.addObstacles(obstacleGraphics);
}

void draw() {
  background(0);
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
  context.begin(); //<>//
  context.getGLTextureHandle(sourceGraphics, tempArray);
  int sourceGraphicsGL = tempArray[0];
  context.beginDraw(fluid.tex_density.dst);
  shaderDensity.begin();
  shaderDensity.uniform1f("time", 0);//(millis() / 500.0f) % 1.0f);
  shaderDensity.uniform2f("wh", fluid.fluid_w, fluid.fluid_h);
  shaderDensity.uniformTexture("texture_old", fluid.tex_density.src);
  shaderDensity.uniformTexture("texture_new", sourceGraphicsGL);
  shaderDensity.drawFullScreenQuad();
  shaderDensity.end();
  context.endDraw();
  context.end();
  fluid.tex_density.swap();  
  fluid.update(); //<>//
  
  // Update particles
  particleSystem.update(fluid);
  
  //particleSystem.tex_particles.swap();
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
  
  
  
  
  // Draw fluid + particles

  fluid.renderFluidTextures(fluidGraphics, 0);
  //particleSystem.render(fluidGraphics, null, 0);
  
  fluidGraphics.beginDraw();
  fluidGraphics.blendMode(PConstants.BLEND);
  //if(background == 0) dst.blendMode(PConstants.ADD); // works nicely on black background
  
  context.begin();
  shaderParticlesRender.begin();
  //shaderParticlesRender.uniform2f     ("wh_viewport", w, h);
  shaderParticlesRender.uniform2i     ("num_particles", particleSystem.particles_x, particleSystem.particles_y);
  shaderParticlesRender.uniformTexture("tex_particles", particleSystem.tex_particles.src);
  shaderParticlesRender.drawFullScreenPoints(particleSystem.particles_x * particleSystem.particles_y);
  shaderParticlesRender.end();
  context.end("ParticleSystem.render");

  fluidGraphics.endDraw();
  
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
