#version 150

out vec4 glFragColor;

uniform sampler2D tex_particles;
uniform vec2 wh_particles;

void main(){

  // prepare particle index, based on the current fragment position

  vec4 particle_data = texture(tex_particles, gl_FragCoord.xy / wh_particles);

  // Original position
  vec2 reset_position = gl_FragCoord.xy / wh_particles;


  if(distance(particle_data.xy, reset_position) > 0.3 && length(particle_data.zw) < 0.0000001) {
    particle_data.xy = reset_position;
    particle_data.zw = vec2(0, 0);
  }

  glFragColor = particle_data;
}

