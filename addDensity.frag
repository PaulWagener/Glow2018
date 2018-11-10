#version 150

precision mediump float;
precision mediump int;

out vec4 glFragColor;

uniform float time;
uniform vec2 wh;
uniform sampler2D texture_old;
uniform sampler2D texture_new;

vec3 hsv2rgb(float hue, float saturation, float value) {
  int h = int(hue * 6);
  float f = hue * 6 - h;
  float p = value * (1 - saturation);
  float q = value * (1 - f * saturation);
  float t = value * (1 - (1 - f) * saturation);

  switch (h) {
    case 0: return vec3(value, t, p);
    case 1: return vec3(q, value, p);
    case 2: return vec3(p, value, t);
    case 3: return vec3(p, q, value);
    case 4: return vec3(t, p, value);
    case 5: return vec3(value, p, q);
    default: return vec3(0, 0, 0);
  }
}

void main(){
  vec2 posn = gl_FragCoord.xy / wh;
  vec4 data_old = texture(texture_old, posn);
  vec4 data_new = texture(texture_new, posn);

  // Darken background
  if(length(data_old.xyz) > 0.3) {
    data_old = mix(data_old, vec4(0, 0, 0, 1), 0.001);
  }

  float mix = 0.0;

  float length = length(data_new.xyz);

  if(length > 0.0) {
    mix = 1.0;
  }

  vec3 color = hsv2rgb(mod(time + posn.x + posn.y, 1.0), 1.0, (sin(posn.x*20.0 - posn.y * 12 + time * 3.1415 * 2) + 2.5) / 2.0);

  glFragColor = mix(data_old, vec4(color, 1.0), mix);
}

