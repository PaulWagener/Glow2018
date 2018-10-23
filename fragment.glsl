
uniform sampler2D flow;
uniform sampler2D rainbow;
varying vec2 flowPosition;
uniform sampler2D prevRender;

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {

  //gl_FragColor = vec4(flowPosition.x, flowPosition.y, 0.3, 1);//;

  // Draw a distorted version of the previous render
  vec2 renderPos = flowPosition.xy;
  renderPos.y = 1 - renderPos.y;
  gl_FragColor = texture2D(prevRender, renderPos) * 0.997;


  //*
  // Draw a green warp grid accros

  /*
  if(int(flowPosition.x * 300) % 10 == 0
  || int(flowPosition.y * 300) % 10 == 0) {
    gl_FragColor = vec4(0, 1, 0, 1);
  }
  //*/
}