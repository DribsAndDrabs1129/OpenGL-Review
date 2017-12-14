//
//  ViewController.m
//  OpenGLReview
//
//  Created by Channe Sun on 2017/12/7.
//  Copyright © 2017年 HUST. All rights reserved.
//

#import "ForthViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <AVFoundation/AVFoundation.h>

#define  TEST_PIC_NAME @"blue.png"

typedef NS_ENUM(NSUInteger, OpenGLShaderType) {
    SC_OPENGL_SHDER_FILTER_MOTIONBLUR,
    SC_OPENGL_SHDER_FILTER_GAUSSIANBLUR
};

@interface ForthViewController ()
{
    EAGLContext *_eaglContext;
    CAEAGLLayer *_eaglLayer;
    
    GLuint _renderBuffer;
    GLuint _frameBuffer;
    GLuint texName;
    
    GLuint _positionSlot;
    GLuint _textureSlot;
    GLuint _textureCoordSlot;
    GLuint _colorSlot;
    GLuint _Saturation_brightness;
    GLuint _enableGrayScale;
    GLuint _enableNegation;
    
    GLuint _programHandle;
    
    NSArray *picNameArr;
    NSString *picName;
    
    //boxblurfilter
    GLuint _upOffset;
    GLuint _bottomOffset;
    GLuint _radiusOffset;
    GLuint _dir;
    
    CGFloat upPara;
    CGFloat bottomPara;
    CGFloat radiusPara;
    OpenGLShaderType shaderType;
    
    BOOL shouldUnion;
}

@end

@implementation ForthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    upPara = 0.0;
    bottomPara = 0.0;
    shouldUnion = NO;
    
    shaderType = SC_OPENGL_SHDER_FILTER_MOTIONBLUR;
    
    picNameArr = @[@"1.jpg",@"2.jpg",@"3.png",@"4.jpg",@"5.jpg",@"6.jpg",@"7.jpg"];
    
    picName = picNameArr[2];
    
    [self setupOpenGL];
    
    [self setRenderBuffer];
    
    [self setViewPort];
    
    [self setShader];
    
    [self setTexture];
    
    [self drawTrangle];
    
    [self.view bringSubviewToFront:self.backView];
}

#pragma mark - Action

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.backView.hidden = !self.backView.hidden;
    self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
}

- (IBAction)changeAction:(UIButton *)sender {
    NSInteger index = [picNameArr indexOfObject:picName];
    picName = [picNameArr objectAtIndex:(index + 1)%picNameArr.count];
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self setTexture];
    
    [self drawTrangle];
}

- (IBAction)switchValueChanged:(UISwitch *)sender {
    if (_leftSwitch == sender) {
        if (_leftSwitch.isOn) {
            shouldUnion = YES;
        }
        else{
            shouldUnion = NO;
        }
    }
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    [self setShader];
    [self setTexture];
    [self drawTrangle];
}

- (IBAction)valueChanged:(UISlider *)sender {
    CGFloat temValue = sender.value/1000.0;//0 ~ 0.1
    temValue = temValue;
    NSLog(@"%f",temValue);
    
    if (shouldUnion && shaderType == SC_OPENGL_SHDER_FILTER_MOTIONBLUR && _radiusSlider != sender) {
        upPara = temValue;
        bottomPara = temValue;
        _upLabel.text = [NSString stringWithFormat:@"%.0f",(temValue)* 1000.0];
        _bottomLabel.text = [NSString stringWithFormat:@"%.0f",(temValue)* 1000.0];
        _upSlider.value = sender.value;
        _bottomSlider.value = sender.value;
    }
    else{
        if (_upSlider == sender) {
            upPara = temValue;
            _upLabel.text = [NSString stringWithFormat:@"%.0f",(temValue)* 1000.0];
        }
        else if (_bottomSlider == sender){
            bottomPara = temValue;
            _bottomLabel.text = [NSString stringWithFormat:@"%.0f",(temValue)* 1000.0];
        }
        else if (_radiusSlider == sender){
            radiusPara = temValue;
            _radiusLabel.text = [NSString stringWithFormat:@"%.1f",(temValue)];
        }
    }
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self drawTrangle];
}

#pragma mark - OpenGL Relate

- (void)setupOpenGL{
    /***  设置上下文   ***/
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; //opengl es 2.0
    [EAGLContext setCurrentContext:_eaglContext]; //设置为当前上下文。
    
    /***  添加layer层   ***/
    _eaglLayer = [CAEAGLLayer layer];
    _eaglLayer.frame = self.view.bounds;
    _eaglLayer.backgroundColor = [UIColor yellowColor].CGColor;
    _eaglLayer.opaque = YES;
    
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.view.layer addSublayer:_eaglLayer];
}

- (void)setRenderBuffer{
    /***  清除帧缓存和渲染缓存   ***/
    if (_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    
    if (_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    /***  设置帧缓存和渲染缓存   ***/
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    GLint width = 0;
    GLint height = 0;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    //check success
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object: %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)setViewPort{
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

- (void)setShader{
    NSString *vshName = nil;
    NSString *fshName = nil;
    if (shaderType == SC_OPENGL_SHDER_FILTER_MOTIONBLUR) {
        vshName = @"MotionBlurVertex.vsh";
        fshName = @"MotionBlurFragment.fsh";
    }
    else if (shaderType == SC_OPENGL_SHDER_FILTER_GAUSSIANBLUR){
        vshName = @"GaussianBlurFilterVertex.vsh";
        fshName = @"GaussianBlurFilterFragment.fsh";
    }
    
    GLuint vertexShaderName = [self compileShader:vshName withType:GL_VERTEX_SHADER];
    if (!vertexShaderName) {
        NSLog(@"vsh complie error");
        return;
    }
    
    GLuint fragmenShaderName = [self compileShader:fshName withType:GL_FRAGMENT_SHADER];
    if (!fragmenShaderName) {
        NSLog(@"fsh complie error");
        return;
    }
    
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShaderName);
    glAttachShader(_programHandle, fragmenShaderName);
    
    glLinkProgram(_programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    _positionSlot = glGetAttribLocation(_programHandle,[@"in_Position" UTF8String]);
    _textureSlot = glGetUniformLocation(_programHandle, [@"in_Texture" UTF8String]);
    _textureCoordSlot = glGetAttribLocation(_programHandle, [@"in_TexCoord" UTF8String]);
    _colorSlot = glGetAttribLocation(_programHandle, [@"in_Color" UTF8String]);
    
    if (shaderType == SC_OPENGL_SHDER_FILTER_MOTIONBLUR){
        _upOffset = glGetUniformLocation(_programHandle, [@"texelWidthOffset" UTF8String]);
        _bottomOffset = glGetUniformLocation(_programHandle, [@"texelHeightOffset" UTF8String]);
    }
    else if (shaderType == SC_OPENGL_SHDER_FILTER_GAUSSIANBLUR){
        _radiusOffset = glGetUniformLocation(_programHandle, [@"radius" UTF8String]);
        _dir = glGetUniformLocation(_programHandle, [@"dir" UTF8String]);
    }
    
    glUseProgram(_programHandle);
}

- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *path = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError *error = nil;
    NSString *shaderString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"%@", error.localizedDescription);
    }
    
    const char * shaderUTF8 = [shaderString UTF8String];
    GLint shaderLength = (GLint)[shaderString length];
    GLuint shaderHandle = glCreateShader(shaderType);
    glShaderSource(shaderHandle, 1, &shaderUTF8, &shaderLength);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shaderHandle;
}

- (void)setTexture{
    glDeleteTextures(1, &texName);
    
    /***  Generate Texture   ***/
    texName = [self getTextureFromImage:[UIImage imageNamed:picName]];
    
    /***  Bind Texture   ***/
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texName);
    glUniform1i(_textureSlot, 1);
}

- (GLuint)getTextureFromImage:(UIImage *)image {
    CGImageRef imageRef = [image CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    GLubyte* textureData = (GLubyte *)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    glEnable(GL_TEXTURE_2D);
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(textureData);
    return texName;
}

- (void)drawTrangle {
    UIImage *image = [UIImage imageNamed:picName];
    CGRect realRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.view.bounds);
    CGFloat widthRatio = realRect.size.width/self.view.bounds.size.width;
    CGFloat heightRatio = realRect.size.height/self.view.bounds.size.height;
    
    //    const GLfloat vertices[] = {
    //        -1, -1, 0,   //左下
    //        1,  -1, 0,   //右下
    //        -1, 1,  0,   //左上
    //        1,  1,  0 }; //右上
    const GLfloat vertices[] = {
        -widthRatio, -heightRatio, 0,   //左下
        widthRatio,  -heightRatio, 0,   //右下
        -widthRatio, heightRatio,  0,   //左上
        widthRatio,  heightRatio,  0 }; //右上
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    // normal
    static const GLfloat coords[] = {
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    glEnableVertexAttribArray(_textureCoordSlot);
    glVertexAttribPointer(_textureCoordSlot, 2, GL_FLOAT, GL_FALSE, 0, coords);
    
    static const GLfloat colors[] = {
        1, 0, 0, 1,
        0, 0, 0, 1,
        0, 0, 0, 1,
        1, 0, 0, 1
    };
    
    glEnableVertexAttribArray(_colorSlot);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 0, colors);
    
    if (shaderType == SC_OPENGL_SHDER_FILTER_MOTIONBLUR){
        glUniform1f(_upOffset, upPara);
        glUniform1f(_bottomOffset, bottomPara);
    }
    else if (shaderType == SC_OPENGL_SHDER_FILTER_GAUSSIANBLUR){
        glUniform1f(_radiusOffset, radiusPara/100.0);
        glUniform2f(_dir, 10.0, 10.0);
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

