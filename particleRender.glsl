// My render

#version 150

#define SHADER_VERT 0
#define SHADER_FRAG 0


// uniforms are shared
//uniform vec2      wh_viewport;
uniform ivec2     num_particles;
uniform sampler2D tex_particles;


#if SHADER_VERT

out vec4 particle;

void main(){

  // // get point index / vertex index
  int point_id = gl_VertexID;

  // // get position (xy)
  int row = point_id / num_particles.x;
  int col = point_id - num_particles.x * row;

  // // compute texture location [0, 1]
  vec2 posn = (vec2(col, row)+0.5) / vec2(num_particles);

  // // get particel pos, vel
  particle = texture(tex_particles, posn);

  // finish vertex coordinate
  gl_Position = vec4(particle.xy * 2.0 - 1.0, 0, 1); // ndc: [-1, +1]
  gl_PointSize = length(particle.zw) / 5;
}

#endif // #if SHADER_VERT

#if SHADER_FRAG

in vec4 particle;

out vec4 out_frag;

void main(){
  float alpha = length(particle.zw) / 20;

  if(alpha > 0.4) {
    alpha = 0.4;
  }

  //float vel = mod(length(particle.zw) / 20, 0.1) * 10;
  vec3 color = vec3(1, 1, 1);

  out_frag = vec4(color, alpha);
}


#endif // #if SHADER_VERT
