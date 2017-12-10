precision mediump float;
uniform sampler2D in_Texture;

varying vec3 out_Luminance_Saturation;

varying vec2 out_TexCoord;
varying vec3 greyScaleColor;

const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main(void) {
    vec4 textureColor = texture2D(in_Texture, out_TexCoord);
    float luminance = dot(textureColor.rgb, W);
    
    vec3 greyScaleColor = vec3(luminance);
    
    gl_FragColor = vec4(1.0 - greyScaleColor[0], 1.0 - greyScaleColor[1], 1.0 - greyScaleColor[2], textureColor.w);
}


