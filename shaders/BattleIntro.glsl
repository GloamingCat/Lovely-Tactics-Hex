
/*=================================================================================================

Battle Intro Shader 
--------------------------------------------------------------------------------------------------
Shader that modifies the screen to transitate from normal field to battle field.

=================================================================================================*/

uniform float time;

vec4 effect(vec4 color, sampler2D texture, vec2 texture_coords, vec2 screen_coords) {
  vec4 initialColor = texture2D(texture, texture_coords) * color;
  initialColor *= (1.0 - time);
  return initialColor;
}