attribute vec4 in_Position;

attribute vec2 in_TexCoord;
varying vec2 out_TexCoord;


void main(void) {
    gl_Position = in_Position;
    out_TexCoord = in_TexCoord;
}
