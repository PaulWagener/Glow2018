#version 150

out vec4 glFragColor;

uniform sampler2D tex_particles;
uniform vec2 wh_particles;

void main(){

  // prepare particle index, based on the current fragment position

  vec4 particle_data = texture(tex_particles, gl_FragCoord.xy / wh_particles);

  // Original position
  vec2 reset_position = gl_FragCoord.xy / wh_particles;

  // Force back to original position
  vec2 vectorBack = reset_position - particle_data.xy;

  particle_data.xy += vectorBack / 200;

  glFragColor = particle_data;
}

