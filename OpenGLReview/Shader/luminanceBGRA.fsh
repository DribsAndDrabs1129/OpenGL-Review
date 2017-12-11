precision mediump float;
uniform sampler2D in_Texture;

varying vec2 out_Saturation_Brightness;

varying float out_greyScale;
varying float out_negation;

varying vec2 out_TexCoord;
varying vec3 greyScaleColor;

const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main(void) {
    vec4 textureColor = texture2D(in_Texture, out_TexCoord);
    
    textureColor = vec4(textureColor.b,textureColor.g,textureColor.r,textureColor.w);
    
    float luminance = dot(textureColor.rgb, W);
    
    vec3 greyScaleColor = vec3(luminance);

    //saturation
    textureColor = vec4(mix(greyScaleColor, textureColor.rgb, out_Saturation_Brightness[0]), textureColor.w);
    
    //brightness
    textureColor = vec4(textureColor.rgb + vec3(out_Saturation_Brightness[1]), textureColor.w);

    //greyscale
    if (out_greyScale == 1.0) {
        luminance = dot(textureColor.rgb, W);
        textureColor = vec4(vec3(luminance), textureColor.w);
    }
    
    //negation
    if (out_negation == 1.0) {
        textureColor = vec4(vec3(1.0 - textureColor.r, 1.0 - textureColor.g, 1.0 - textureColor.b), textureColor.w);
    }

    gl_FragColor = vec4(min(textureColor.r,1.0),min(textureColor.g,1.0),min(textureColor.b,1.0),textureColor.w);
}

