attribute vec4 in_Position;

attribute vec2 in_TexCoord;
varying vec2 out_TexCoord;

attribute float in_greyScale;
varying float out_greyScale;

attribute float in_negation;
varying float out_negation;

attribute vec2 in_Saturation_Brightness;
varying vec2 out_Saturation_Brightness;

void main(void) {
    gl_Position = in_Position;
    out_TexCoord = in_TexCoord;
    out_Saturation_Brightness = in_Saturation_Brightness;
    out_greyScale = in_greyScale;
    out_negation = in_negation;
}
