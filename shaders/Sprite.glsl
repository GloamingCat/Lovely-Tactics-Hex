
/*=================================================================================================

Sprite Shader 
--------------------------------------------------------------------------------------------------
Draws the sprite with HSV (hue, saturation, value/brightness) modifications.

=================================================================================================*/

// HSV modifier.
uniform vec3 phsv = vec3(0.0, 1.0, 1.0);

// Converts a (r, g, b) to a (h, s, v).
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Converts a (h, s, v) to a (r, g, b).
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Code above from: 
// https://gamedev.stackexchange.com/questions/59797/glsl-shader-change-hue-saturation-brightness

#ifdef PIXEL
vec4 effect(vec4 color, sampler2D texture, vec2 texture_coords, vec2 screen_coords) {
  vec4 initialColor = texture2D(texture, texture_coords);
  // Change hue
  vec3 hsv = rgb2hsv(initialColor.rgb);
  hsv.x = mod(phsv.x + hsv.x, 1.0);
  // Multiply RGB
  vec3 rgb = hsv2rgb(hsv) * color.rgb;
  // Change brightness / saturation
  hsv = rgb2hsv(rgb);
  hsv.yz = clamp(phsv.yz * hsv.yz, 0.0, 1.0);
  return vec4(hsv2rgb(hsv), initialColor.a * color.a);
}
#endif