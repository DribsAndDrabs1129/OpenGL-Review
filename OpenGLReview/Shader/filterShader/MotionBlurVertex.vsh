attribute vec4 in_Position;
attribute vec2 in_TexCoord;

//uniform vec2 directionalTexelStep;

uniform float texelWidthOffset;
uniform float texelHeightOffset;

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
    gl_Position = in_Position;
    
    vec2 directionalTexelStep = vec2(texelWidthOffset, texelHeightOffset);
    
    textureCoordinate = in_TexCoord;
    oneStepBackTextureCoordinate = in_TexCoord - directionalTexelStep;
    twoStepsBackTextureCoordinate = in_TexCoord - 2.0 * directionalTexelStep;
    threeStepsBackTextureCoordinate = in_TexCoord - 3.0 * directionalTexelStep;
    fourStepsBackTextureCoordinate = in_TexCoord - 4.0 * directionalTexelStep;
    oneStepForwardTextureCoordinate = in_TexCoord + directionalTexelStep;
    twoStepsForwardTextureCoordinate = in_TexCoord + 2.0 * directionalTexelStep;
    threeStepsForwardTextureCoordinate = in_TexCoord + 3.0 * directionalTexelStep;
    fourStepsForwardTextureCoordinate = in_TexCoord + 4.0 * directionalTexelStep;
}

