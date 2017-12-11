//
//  ViewController.m
//  OpenGLReview
//
//  Created by Channe Sun on 2017/12/7.
//  Copyright © 2017年 HUST. All rights reserved.
//

#import "FirstViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <AVFoundation/AVFoundation.h>

#define  TEST_PIC_NAME @"blue.png"

@interface FirstViewController ()
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
    
    CGFloat grayScalePara;          // 0 or 1
    CGFloat negationPara;           // 0 or 1
    CGFloat saturationPara;
    CGFloat brightnessPara;
    
    NSArray *picNameArr;
    NSString *picName;
}

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    grayScalePara = 0.0;
    negationPara = 0.0;
    saturationPara = 1.0;
    brightnessPara = 0.0;
    
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
    if (_grayScaleSwitch == sender) {
        grayScalePara = sender.on ? 1.0 : 0;
    }
    if (_negationSwitch == sender) {
        negationPara = sender.on ? 1.0 : 0;
    }
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self drawTrangle];
}

- (IBAction)valueChanged:(UISlider *)sender {
    CGFloat temValue = sender.value / 2.0;
    if (_saturationSlider == sender) {
        saturationPara = temValue + 1.0;
        _saturationLabel.text = [NSString stringWithFormat:@"%.2f",temValue];
    }
    else if (_brightnessSlider == sender){
        brightnessPara = temValue;
        _brightnessLabel.text = [NSString stringWithFormat:@"%.2f",temValue];
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
    GLuint vertexShaderName = [self compileShader:@"vertexShader.vsh" withType:GL_VERTEX_SHADER];
//    GLuint fragmenShaderName = [self compileShader:@"fragmentShader.fsh" withType:GL_FRAGMENT_SHADER];
    GLuint fragmenShaderName = [self compileShader:@"luminance.fsh" withType:GL_FRAGMENT_SHADER];
    
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
    _Saturation_brightness = glGetAttribLocation(_programHandle, [@"in_Saturation_Brightness" UTF8String]);
    _enableGrayScale = glGetAttribLocation(_programHandle, [@"in_greyScale" UTF8String]);
    _enableNegation = glGetAttribLocation(_programHandle, [@"in_negation" UTF8String]);
    
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
    
    //亮度，色度
    GLfloat saturation_brightness[] = {
        saturationPara, brightnessPara,
        saturationPara, brightnessPara,
        saturationPara, brightnessPara,
        saturationPara, brightnessPara
    };
    glEnableVertexAttribArray(_Saturation_brightness);
    glVertexAttribPointer(_Saturation_brightness, 2, GL_FLOAT, GL_FALSE, 0, saturation_brightness);
    
    //灰度图
    GLfloat grayScale[] = {
        grayScalePara,
        grayScalePara,
        grayScalePara,
        grayScalePara
    };
    glEnableVertexAttribArray(_enableGrayScale);
    glVertexAttribPointer(_enableGrayScale, 1, GL_FLOAT, GL_FALSE, 0, grayScale);
    
    //取反
    GLfloat negation[] = {
        negationPara,
        negationPara,
        negationPara,
        negationPara
    };
    glEnableVertexAttribArray(_enableNegation);
    glVertexAttribPointer(_enableNegation, 1, GL_FLOAT, GL_FALSE, 0, negation);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
