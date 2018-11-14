// My render

#version 150

#define SHADER_VERT 0
#define SHADER_FRAG 0


// uniforms are shared
//uniform vec2      wh_viewport;
uniform ivec2     num_particles;
uniform sampler2D tex_particles;
uniform sampler2D tex_glow;


#if SHADER_VERT

out vec4 particle;
out vec4 glowPixel;
out vec2 posn;

void main(){

  // // get point index / vertex index
  int point_id = gl_VertexID;

  // // get position (xy)
  int row = point_id / num_particles.x;
  int col = point_id - num_particles.x * row;

  // // compute texture location [0, 1]
  posn = (vec2(col, row)+0.5) / vec2(num_particles);

  // // get particle pos, vel
  particle = texture(tex_particles, posn);

  // finish vertex coordinate
  gl_Position = vec4(particle.xy * 2.0 - 1.0, 0, 1); // ndc: [-1, +1]
  gl_PointSize = 1;
  glowPixel = texture(tex_glow, posn);
}

#endif // #if SHADER_VERT

#if SHADER_FRAG

in vec4 particle;
in vec4 glowPixel;
in vec2 posn;

out vec4 out_frag;

void main(){
  if(glowPixel.w > 0) {


    float alpha = glowPixel.w;

    float distance = distance(posn, particle.xy);
    //distance = 0;
    alpha /= distance * 20;
    //alpha /= distance;
    //float vel = mod(length(particle.zw) / 20, 0.1) * 10;
    vec4 color = glowPixel;

    if(color.w < 0.3) {
      color.w = 0.3;
    }

    out_frag = color;
  } else {
    out_frag = vec4(0, 0, 0, 0);
  }
}


#endif // #if SHADER_VERT
