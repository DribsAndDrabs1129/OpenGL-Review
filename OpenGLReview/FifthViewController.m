//
//  FifthViewController.m
//  OpenGLReview
//
//  Created by Channe Sun on 2018/1/3.
//  Copyright © 2018年 HUST. All rights reserved.
//

#import "FifthViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <AVFoundation/AVFoundation.h>

#define  TEST_PIC_NAME @"blue.png"

@interface FifthViewController ()
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
    
    GLuint _enableBlur;
    GLuint _blurType;
    GLuint _tcOffset;
    
    GLuint _programHandle;
    GLuint _offscreenFramebuffer;
    
    int blurTypePara;           //0 gaussian blur
    int enableBlurPara;         //0 disable; 1 enable
    
    GLfloat blurStep;
    
    NSArray *picNameArr;
    NSArray *blurTypeArr;
    NSString *picName;
}

@end

@implementation FifthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    enableBlurPara = 1;
    blurTypePara = 0;
    blurStep = 0.0f;
    
    picNameArr = @[@"1.jpg",@"2.jpg",@"3.png",@"4.jpg",@"5.jpg",@"6.jpg",@"7.jpg"];
    blurTypeArr = @[@"Gaussian",@"Median Filter",@"Sharpen",@"Dilate",@"Erode"];
    picName = picNameArr[2];
    
    [self setupOpenGL];
    
    [self setRenderBuffer];
    
    [self setViewPort];
    
    [self setShader];
    
    [self setTexture];
    
//    [self drawTrangle];
    
    [self.view bringSubviewToFront:self.backView];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tips" message:@"Test Gaussian blur" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
        [self drawTrangle];
    });
}

#pragma mark - Action

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.backView.hidden = !self.backView.hidden;
    self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
}

- (IBAction)blurTypeAction:(id)sender {
    blurTypePara ++;
    blurTypePara = blurTypePara % blurTypeArr.count;
    [self.blurTypeButton setTitle:blurTypeArr[blurTypePara] forState:UIControlStateNormal];
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
    if (_blurSwitch == sender) {
        enableBlurPara = sender.on ? 1 : 0;
    }
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self drawTrangle];
}

- (IBAction)valueChanged:(UISlider *)sender {
    CGFloat temValue = sender.value;
    blurStep = temValue;
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self drawTrangle];
}

#pragma mark - OffScreen buffer
- (void)createOffscreenBuffer:(UIImage *)image {
    glGenFramebuffers(1, &_offscreenFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFramebuffer);
    
    //Create the texture
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,  image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //Bind the texture to your FBO
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    
    //Test if everything failed
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        printf("failed to make complete framebuffer object %x", status);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)getImageFromBuffer:(int)width withHeight:(int)height {
    GLint x = 0, y = 0;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"image size: %f---%f  \nscreenSize: %f---%f",image.size.width,image.size.height,self.view.frame.size.width,self.view.frame.size.height);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor redColor];
    [self.view addSubview:imageView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [imageView removeFromSuperview];
        
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        glViewport(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
    });
    UIGraphicsEndImageContext();
    
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
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
    
    vshName = @"BlurVertex.vsh";
    fshName = @"BlurFragment.fsh";
    
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
    
    _positionSlot       = glGetAttribLocation(_programHandle,[@"in_Position" UTF8String]);
    _textureSlot        = glGetUniformLocation(_programHandle, [@"in_Texture" UTF8String]);
    _textureCoordSlot   = glGetAttribLocation(_programHandle, [@"in_TexCoord" UTF8String]);
    _colorSlot          = glGetAttribLocation(_programHandle, [@"in_Color" UTF8String]);
    
    //uniform
    _enableBlur    = glGetUniformLocation(_programHandle, [@"enableBlur" UTF8String]);
    _blurType     = glGetUniformLocation(_programHandle, [@"blurType" UTF8String]);
    _tcOffset           = glGetUniformLocation(_programHandle, [@"tcOffset" UTF8String]);
    
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
    //    glDeleteTextures(1, &texName);
    
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

- (void)drawRaw {
    [self setTexture];
    
    const GLfloat vertices[] = {
        -1, -1, 0,   //左下
        1,  -1, 0,   //右下
        -1, 1,  0,   //左上
        1,  1,  0 }; //右上
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
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1
    };
    
    glEnableVertexAttribArray(_colorSlot);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 0, colors);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
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
    
    glUniform1i(_enableBlur, enableBlurPara);
    
    glUniform1i(_blurType, blurTypePara);
    
    [self generateOffset];
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
    //此处相当于将OpenGL渲染的buffer present到context上，会保存下来
}

- (void)generateOffset{
    // Set up texture sampling offset storage
    const GLint tcOffsetColumns = 5;
    const GLint tcOffsetRows    = 5;
    GLfloat   texCoordOffsets[tcOffsetColumns * tcOffsetRows * 2];
    
    // Calculate texture coordinate offsets for kernel convolution effects
    // Note: You can multiply the step to displace the samples further. Do this with diff values horiz and vert and you have directional blur of a sort...
    float xInc = blurStep / (GLfloat)(self.view.bounds.size.width);
    float yInc = blurStep / (GLfloat)(self.view.bounds.size.height);
    
    for (int i = 0; i < tcOffsetColumns; i++)
    {
        for (int j = 0; j < tcOffsetRows; j++)
        {
            texCoordOffsets[(((i*5)+j)*2)+0] = (-2.0f * xInc) + ((GLfloat)i * xInc);
            texCoordOffsets[(((i*5)+j)*2)+1] = (-2.0f * yInc) + ((GLfloat)j * yInc);
        }
    }
    
    //offset
    glUniform2fv(_tcOffset, 50, texCoordOffsets);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
