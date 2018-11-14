#version 150

precision mediump float;
precision mediump int;

out vec2 glFragColor;

uniform vec2  wh;

uniform sampler2D tex_opticalflow;
uniform sampler2D tex_velocity_old;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453) * 2 - 1;
}

void main(){

  vec2 posn = gl_FragCoord.xy / wh;

  vec2 data_old = texture(tex_velocity_old, posn).xy;
  vec2 data_ext = -texture(tex_opticalflow , posn).xy;

  vec2 data_new = data_old;

  float len = clamp(length(data_ext), 0.0, 1.0);

  if (len > 0.0) {

    // Add turbulence
    data_ext.xy += vec2(rand(gl_FragCoord.xy), rand(gl_FragCoord.yx)) * 15 * len;

    data_ext *= 7.0;
    if(length(data_old) > length(data_ext)){
      data_new = data_old;
    } else {
      data_new = mix(data_old, data_ext, 0.3);
    }
  }

  glFragColor = data_new;
}

