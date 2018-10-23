uniform mat4 transform;
attribute vec4 position;

uniform sampler2D flow;
uniform sampler2D prevRender;

varying vec2 flowPosition;

void main() {
  vec4 pos = transform * position;
  //pos.xy += vec2(1.0, 1.0);


  flowPosition = (pos.xy + 1.0) / 2.0;
  flowPosition = vec2(flowPosition.x, 1 - flowPosition.y);

  vec2 displacement = (texture2D(flow, flowPosition.st).xy - 0.501) / 13.0;
  displacement.y = -displacement.y;
  pos.xy += displacement;
  pos.z = -length(displacement);
  //*/
  gl_Position = pos;// + texture2D(flow, flowPosition.st);
}