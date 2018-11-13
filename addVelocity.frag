#version 150

precision mediump float;
precision mediump int;

out vec2 glFragColor;

uniform vec2  wh;

uniform sampler2D tex_opticalflow;
uniform sampler2D tex_velocity_old;

void main(){

  vec2 posn = gl_FragCoord.xy / wh;

  vec2 data_old = texture(tex_velocity_old, posn).xy;
  vec2 data_ext = -texture(tex_opticalflow , posn).xy;

  vec2 data_new = data_old;

  float len = clamp(length(data_ext), 0.0, 1.0);

  if (len > 0.0) {

    data_ext *= 5.0;
    if(length(data_old) > length(data_ext)){
      data_new = data_old;
    } else {
      data_new = mix(data_old, data_ext, 0.3);
    }
  }

  glFragColor = data_new;
}

