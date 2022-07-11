
/*=================================================================================================

Text Shader 
--------------------------------------------------------------------------------------------------
Draws the text with an outline.

=================================================================================================*/

// Size of the pixel. It depends on the text's texture size.
extern vec2 pixelSize = vec2(0.001f, 0.001f);
// Scale of the font.
extern vec2 scale = vec2(1, 1);
// Width of the outline. 1 pixel by default.
extern number outlineSize = 1; // in pixels
// Color of the outline (customized). Black by default.
extern vec4 outlineColor = vec4(0, 0, 0, 1);
// The scale of the step
extern vec2 stepSize = vec2(1, 1);

vec4 effect(vec4 color, sampler2D texture, vec2 texture_coords, vec2 screen_coords) {
  vec4 initialColor = texture2D(texture, texture_coords);
  number initialAlpha = initialColor[3];
  
  // Calculate alpha in neighborhood.
  number outlineAlpha = 0;
  for (number i = -outlineSize; i <= outlineSize; i += stepSize.x) {
      for (number j = -outlineSize; j <= outlineSize; j += stepSize.y) {
          vec4 neighborColor = texture2D(texture, texture_coords + vec2(i, j) * scale * pixelSize);
          outlineAlpha += neighborColor[3];
      }
  }
  
  // Combine initial and outline colors.
  outlineAlpha = min(outlineAlpha / (outlineSize * outlineSize), 1) * outlineColor[3];
  number finalAlpha = initialAlpha + (1 - initialAlpha) * outlineAlpha;
  vec4 finalColor = (initialAlpha * initialColor + (1 - initialAlpha) * outlineAlpha * outlineColor);
  finalColor[3] = finalAlpha;
  
  return finalColor * color;
}