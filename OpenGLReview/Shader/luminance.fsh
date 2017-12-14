precision mediump float;
uniform sampler2D in_Texture;

uniform float saturation;
uniform float brightness;
uniform int greyScale;
uniform int negation;

varying vec2 out_TexCoord;
varying vec3 greyScaleColor;

const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main(void) {
    vec4 textureColor = texture2D(in_Texture, out_TexCoord);
    
    float luminance = dot(textureColor.rgb, W);
    
    vec3 greyScaleColor = vec3(luminance);

    //saturation
    textureColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
    
    //brightness
    textureColor = vec4(textureColor.rgb + vec3(brightness), textureColor.w);

    //greyscale
    if (greyScale == 1) {
        luminance = dot(textureColor.rgb, W);
        textureColor = vec4(vec3(luminance), textureColor.w);
    }
    
    //negation
    if (negation == 1) {
        textureColor = vec4(vec3(1.0 - textureColor.r, 1.0 - textureColor.g, 1.0 - textureColor.b), textureColor.w);
    }

    gl_FragColor = vec4(min(textureColor.r,1.0),min(textureColor.g,1.0),min(textureColor.b,1.0),textureColor.w);
}

