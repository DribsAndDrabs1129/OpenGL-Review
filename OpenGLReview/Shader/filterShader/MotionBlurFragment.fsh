precision highp float;

uniform sampler2D in_Texture;

varying vec2 textureCoordinate;
varying vec2 oneStepBackTextureCoordinate;
varying vec2 twoStepsBackTextureCoordinate;
varying vec2 threeStepsBackTextureCoordinate;
varying vec2 fourStepsBackTextureCoordinate;
varying vec2 oneStepForwardTextureCoordinate;
varying vec2 twoStepsForwardTextureCoordinate;
varying vec2 threeStepsForwardTextureCoordinate;
varying vec2 fourStepsForwardTextureCoordinate;

void main()
{
    // Box weights
    //     lowp vec4 fragmentColor = texture2D(in_Texture, textureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, oneStepBackTextureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, twoStepsBackTextureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, threeStepsBackTextureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, fourStepsBackTextureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, oneStepForwardTextureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, twoStepsForwardTextureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, threeStepsForwardTextureCoordinate) * 0.1111111;
    //     fragmentColor += texture2D(in_Texture, fourStepsForwardTextureCoordinate) * 0.1111111;
    
    lowp vec4 fragmentColor = texture2D(in_Texture, textureCoordinate) * 0.18;
    fragmentColor += texture2D(in_Texture, oneStepBackTextureCoordinate) * 0.15;
    fragmentColor += texture2D(in_Texture, twoStepsBackTextureCoordinate) *  0.12;
    fragmentColor += texture2D(in_Texture, threeStepsBackTextureCoordinate) * 0.09;
    fragmentColor += texture2D(in_Texture, fourStepsBackTextureCoordinate) * 0.05;
    fragmentColor += texture2D(in_Texture, oneStepForwardTextureCoordinate) * 0.15;
    fragmentColor += texture2D(in_Texture, twoStepsForwardTextureCoordinate) *  0.12;
    fragmentColor += texture2D(in_Texture, threeStepsForwardTextureCoordinate) * 0.09;
    fragmentColor += texture2D(in_Texture, fourStepsForwardTextureCoordinate) * 0.05;
    
    gl_FragColor = fragmentColor;
}
