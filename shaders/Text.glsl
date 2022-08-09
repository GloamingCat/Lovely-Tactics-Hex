
/*=================================================================================================

Text Shader 
--------------------------------------------------------------------------------------------------
Draws the text with an outline.

=================================================================================================*/

// Size of the pixel. It depends on the text's texture size.
extern vec2 pixelSize;
// Width of the outline in pixels.
extern number outlineSize;
// The scale of the step
extern vec2 stepSize;

vec4 effect(vec4 color, sampler2D texture, vec2 texture_coords, vec2 screen_coords) {
  vec4 initialColor = texture2D(texture, texture_coords);
  number initialAlpha = initialColor[3];
  
  // Color of the outline (customized). Black by default.
  vec4 outlineColor = vec4(0.0, 0.0, 0.0, 1.0);
  
  // Calculate alpha in neighborhood.
  number outlineAlpha = 0.0;
  for (number i = -outlineSize; i <= outlineSize; i += stepSize.x) {
      for (number j = -outlineSize; j <= outlineSize; j += stepSize.y) {
          vec4 neighborColor = texture2D(texture, texture_coords + vec2(i, j) * pixelSize);
          outlineAlpha += neighborColor[3];
      }
  }
  
  // Combine initial and outline colors.
  outlineAlpha = min(outlineAlpha / (outlineSize * outlineSize), 1.0) * outlineColor[3];
  number finalAlpha = initialAlpha + (1.0 - initialAlpha) * outlineAlpha;
  vec4 finalColor = (initialAlpha * initialColor + (1.0 - initialAlpha) * outlineAlpha * outlineColor);
  finalColor[3] = finalAlpha;
  
  return finalColor * color;
}