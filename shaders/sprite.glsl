
/*=================================================================================================

Sprite Shader 
--------------------------------------------------------------------------------------------------
Draws the sprite with HSV (hue, saturation, value/brightness) modifications.

=================================================================================================*/

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

// Sprite's HSV values. All of them are real numbers from 0 to 1.
varying vec3 phsv;

#ifdef VERTEX
// Vertex
attribute vec3 vhsv;
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    phsv = vhsv;
    // The order of operations matters when doing matrix multiplication.
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, sampler2D texture, vec2 texture_coords, vec2 screen_coords) {
  vec4 initialColor = texture2D(texture, texture_coords) * color;
  vec3 hsv = rgb2hsv(initialColor.rgb);
  hsv.x = mod(phsv.x + hsv.x, 1.0);
  hsv.yz = clamp(phsv.yz * hsv.yz, 0, 1);

  return vec4(hsv2rgb(hsv), initialColor.a);
}
#endif
