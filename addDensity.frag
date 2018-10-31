#version 150

precision mediump float;
precision mediump int;

out vec4 glFragColor;

uniform vec3 color;
uniform vec2 wh;
uniform sampler2D texture_old;
uniform sampler2D texture_new;

void main(){
  vec2 posn = gl_FragCoord.xy / wh;
  vec4 data_old = texture(texture_old, posn);
  vec4 data_new = texture(texture_new, posn);

  float mix = 0.0;

  float length = length(data_new.xyz);

  if(length > 0.5) {
    mix = length;
  }

  glFragColor = mix(data_old, vec4(color, 1.0), mix);
}