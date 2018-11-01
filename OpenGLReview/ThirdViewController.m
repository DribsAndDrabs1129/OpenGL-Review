//
//  ThirdViewController.m
//  OpenGLReview
//
//  Created by Channe Sun on 2017/12/8.
//  Copyright © 2017年 HUST. All rights reserved.
//

#import "ThirdViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/gl.h>

#define ViewWidth  [UIScreen mainScreen].bounds.size.width
#define ViewHeight [UIScreen mainScreen].bounds.size.height

@interface ThirdViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{
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
}

@end

@implementation ThirdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.openGLView.frame = CGRectMake(0, ViewHeight/2.0, ViewWidth, ViewHeight/2.0);
    [self setupVideoSession];
    [self initOpenGL];
    [self.view bringSubviewToFront:self.openGLView];
    [self.view bringSubviewToFront:self.testImageView];
    [self.view bringSubviewToFront:self.backView];
}

- (void)initOpenGL{
    grayScalePara = 0.0;
    negationPara = 0.0;
    saturationPara = 1.0;
    brightnessPara = 0.0;
    
    [self setupOpenGL];
    
    [self setRenderBuffer];
    
    [self setViewPort];
    
    [self setShader];
    
    [self setTexture];
    
    [self drawTrangle];
}

#pragma mark - Action

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.backView.hidden = !self.backView.hidden;
    self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
}

- (IBAction)changeAction:(UIButton *)sender {
//    NSInteger index = [picNameArr indexOfObject:picName];
//    picName = [picNameArr objectAtIndex:(index + 1)%picNameArr.count];
//
//    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT);
//
//    [self setTexture];
//
//    [self drawTrangle];
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
    
//    [self drawTrangle];
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
    
//    [self drawTrangle];
}

#pragma mark - Video

- (void)setupVideoSession{
    NSError *error = nil;
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    AVCaptureDeviceDiscoverySession *devices = [AVCaptureDeviceDiscoverySession   discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    AVCaptureDevice *inputDevice;
    NSArray *devicesIOS  = devices.devices;
    for (AVCaptureDevice *device in devicesIOS) {
        if ([device position] == AVCaptureDevicePositionBack) {
            inputDevice = device;
            break;
        }
    }
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice
                                                                        error:&error];
    if (!input) {
        // Handling the error appropriately.
    }
    [session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];//创建一个视频数据输出流
    [session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    // Specify the pixel format
    output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                            [NSNumber numberWithInt: ViewWidth], (id)kCVPixelBufferWidthKey,
                            [NSNumber numberWithInt: ViewHeight/2.0], (id)kCVPixelBufferHeightKey,
                            nil, nil];
    
    AVCaptureVideoPreviewLayer* preLayer = [AVCaptureVideoPreviewLayer layerWithSession: session];
    //preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preLayer.frame = CGRectMake(0, 0, ViewWidth, ViewHeight/2.0);
    preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:preLayer];
    // If you wish to cap the frame rate to a known value, such as 15 fps, set
    // minFrameDuration.
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in output.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
    }
    inputDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
    
    // Start the session running to start the flow of data
    [session startRunning];
}

#pragma mark - VideoCapture Relate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    // Create a UIImage from the sample buffer data
    [self getBufferData1:sampleBuffer];
}

- (void)getBufferData1:(CMSampleBufferRef)sampleBuffer{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
//    if (!colorSpace){
//        NSLog(@"CGColorSpaceCreateDeviceRGB failure");
//    }

    // Get the base address of the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the data size for contiguous planes of the pixel buffer.
//    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply
//    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize,NULL);
    
    // Create a bitmap image from data supplied by our data provider
//    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, provider, NULL, true, kCGRenderingIntentDefault);
//    CGDataProviderRelease(provider);
//    CGColorSpaceRelease(colorSpace);
//    CGImageRelease(cgImage);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        glDeleteTextures(1, &texName);
        
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &texName);
        glBindTexture(GL_TEXTURE_2D, texName);
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, baseAddress);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, texName);
        glUniform1i(_textureSlot, 1);
        [self drawTrangle];
    });
}

- (void)getBufferData:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    UIImage *image = [UIImage imageWithCGImage:imageRef];
//    UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight];
    dispatch_async(dispatch_get_main_queue(), ^{
        texName = [self getTextureFromImage:image];
        /***  Bind Texture   ***/
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, texName);
        glUniform1i(_textureSlot, 1);
        [self drawTrangle];
//        self.testImageView.image = image;
    });
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRelease(imageRef);
    
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
}

#pragma mark - OpenGL Relate

- (void)setupOpenGL{
    /***  设置上下文   ***/
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; //opengl es 2.0
    [EAGLContext setCurrentContext:_eaglContext]; //设置为当前上下文。
    
    /***  添加layer层   ***/
    _eaglLayer = [CAEAGLLayer layer];
    _eaglLayer.frame = self.openGLView.bounds;
    _eaglLayer.backgroundColor = [UIColor yellowColor].CGColor;
    _eaglLayer.opaque = YES;
    
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [self.openGLView.layer addSublayer:_eaglLayer];
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
    glViewport(0, 0, self.openGLView.bounds.size.width, self.openGLView.bounds.size.height);
}

- (void)setShader{
    GLuint vertexShaderName = [self compileShader:@"vertexShaderiOSCamera.vsh" withType:GL_VERTEX_SHADER];
    if (!vertexShaderName) {
        NSLog(@"vsh complie error");
        return;
    }

    GLuint fragmenShaderName = [self compileShader:@"luminanceBGRA.fsh" withType:GL_FRAGMENT_SHADER];
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
    /***  Generate Texture   ***/
    texName = [self getTextureFromImage:[UIImage imageNamed:@"2.jpg"]];
    
    /***  Bind Texture   ***/
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texName);
    glUniform1i(_textureSlot, 1);
}

- (GLuint)getTextureFromImageData:(NSData *)data{
    UIImage *image = [[UIImage alloc] initWithData:data];
    return [self getTextureFromImage:image];
}

- (GLuint)getTextureFromImage:(UIImage *)image {
    CGImageRef imageRef = [image CGImage];
    return [self getTextureFromCGImageRef:imageRef];
}

- (GLuint)getTextureFromCGImageRef:(CGImageRef)imageRef{
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
    
    glDeleteTextures(1, &texName);

    glEnable(GL_TEXTURE_2D);
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
    CGSize imageSize = CGSizeMake(ViewWidth, ViewHeight/2.0);
    CGRect realRect = AVMakeRectWithAspectRatioInsideRect(imageSize,self.openGLView.bounds);
    CGFloat widthRatio = realRect.size.width/self.openGLView.bounds.size.width;
    CGFloat heightRatio = realRect.size.height/self.openGLView.bounds.size.height;
    
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
//        1, 0,
//        1, 1,
//        0, 0,
//        0, 1
        
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
