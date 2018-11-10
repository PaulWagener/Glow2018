
uniform sampler2D texmex;
uniform float thresholdTop;
uniform float thresholdBottom;
varying vec4 vertTexCoord;
uniform bool debug;

float map(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

void main()
{
  float depth = texture2D(texmex, vec2(vertTexCoord.s, 1 - vertTexCoord.t)).x;


  if(depth < 0.5) {
    gl_FragColor = vec4((debug ? 0.5 : 0), 0, 0, 1);
  } else {
    float threshold = mix(thresholdTop, thresholdBottom, 1 - vertTexCoord.t);
    if(depth < threshold) {
      gl_FragColor = vec4(0, (debug ? 0.5 : 0), 0, 1);
    } else {
      depth = map(depth, threshold, 1.0, 0.0, 1.0);
      gl_FragColor = vec4(depth, depth, depth, 1);
    }
  }
}