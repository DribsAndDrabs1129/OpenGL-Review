//
//  SecondViewController.m
//  OpenGLReview
//
//  Created by Channe Sun on 2017/12/8.
//  Copyright © 2017年 HUST. All rights reserved.
//

#import "SecondViewController.h"
#import <OpenGLES/ES2/gl.h>

#import "AGLKContext.h"
#import <AVFoundation/AVFoundation.h>

typedef struct {
    GLKVector3  positionCoords;
    GLKVector2  textureCoords;
}
SceneVertex;

@interface SecondViewController (){
    GLuint _Buffer;
    NSArray *picNameArr;
    NSString *picName;
    GLuint vertexBufferID;
    CGFloat widthRatio;
    CGFloat heightRatio;
    SceneVertex vertices[4];
}

@end

@implementation SecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    picNameArr = @[@"1.jpg",@"2.jpg",@"3.png",@"4.jpg"];
    
    picName = picNameArr[2];
    
    widthRatio = 1.0;
    heightRatio = 1.0;
    
    [self setVertext];
    
    [self setupGLContext];
    
    [self setupBaseEffect];
    
    [self setClearColor];
    
    [self setBuffer];
    
    [self setTextureWithImage:picName];
}

- (void)setVertext{
    SceneVertex vertices1 = {{-widthRatio, -heightRatio, 0}, {1.0, 1.0}};
    vertices[0] = vertices1;
    
    SceneVertex vertices2 = {{ widthRatio, -heightRatio, 0}, {0.0, 1.0}};
    vertices[1] = vertices2;
    
    SceneVertex vertices3 = {{-widthRatio,  heightRatio, 0}, {1.0, 0.0}};
    vertices[2] = vertices3;
    
    SceneVertex vertices4 = {{ widthRatio,  heightRatio, 0}, {0.0, 0.0}};
    vertices[3] = vertices4;
}

- (void)setupGLContext{
    // Verify the type of view created automatically by the
    // Interface Builder storyboard
    GLKView *view = (GLKView *)self.view;
    NSAssert([view isKindOfClass:[GLKView class]],
             @"View controller's view is not a GLKView");
    
    // Create an OpenGL ES 2.0 context and provide it to the view
    view.context = [[EAGLContext alloc]
                    initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // Make the new context current
    [EAGLContext setCurrentContext:view.context];
}

- (void)setupBaseEffect{
    // Create a base effect that provides standard OpenGL ES 2.0 shading language programs and set constants to be used for all subsequent rendering
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);// RGBA
}

- (void)setClearColor{
    // Set the background color stored in the current context
    GLKVector4 clearColorRGBA = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);// RGBA
    glClearColor(clearColorRGBA.r,clearColorRGBA.g,clearColorRGBA.b, clearColorRGBA.a);
}

- (void)setBuffer{
    GLsizeiptr aStride = sizeof(SceneVertex);
    GLsizei count = sizeof(vertices)/sizeof(SceneVertex);
    GLsizeiptr bufferSizeBytes = aStride * count;
    
    glGenBuffers(1, &_Buffer);// STEP 1
    glBindBuffer(GL_ARRAY_BUFFER, _Buffer);  // STEP 2
    // STEP 3
    glBufferData(GL_ARRAY_BUFFER,  // Initialize buffer contents
                 bufferSizeBytes,  // Number of bytes to copy
                 vertices,         // Address of bytes to copy
                 GL_DYNAMIC_DRAW);  // Hint: cache in GPU memory
}

- (void)resetBuffer{
    GLsizeiptr aStride = sizeof(SceneVertex);
    GLsizei count = sizeof(vertices)/sizeof(SceneVertex);
    GLsizeiptr bufferSizeBytes = aStride * count;
    
    glBindBuffer(GL_ARRAY_BUFFER, _Buffer);  // STEP 2
    // STEP 3
    glBufferData(GL_ARRAY_BUFFER,  // Initialize buffer contents
                 bufferSizeBytes,  // Number of bytes to copy
                 vertices,          // Address of bytes to copy
                 GL_DYNAMIC_DRAW);
}

- (void)setTextureWithImage:(NSString *)imageName{
    if (!imageName) {
        imageName = [picName copy];
    }
    
    CGRect realRect = AVMakeRectWithAspectRatioInsideRect([UIImage imageNamed:imageName].size, self.view.bounds);
    CGFloat temWidthRatio = realRect.size.width/self.view.bounds.size.width;
    CGFloat temHeightRatio = realRect.size.height/self.view.bounds.size.height;
    
    if (temWidthRatio != widthRatio || temHeightRatio != heightRatio) {
        [self updateVertex:temWidthRatio heightR:temHeightRatio];
    }
    
    // Setup texture
    CGImageRef imageRef =
    [[UIImage imageNamed:imageName] CGImage];
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader
                                   textureWithCGImage:imageRef
                                   options:nil
                                   error:NULL];
    
    //删除旧的texture，释放内存
    GLuint oldTexture = self.baseEffect.texture2d0.name;
    glDeleteTextures(1, &oldTexture);
    
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.baseEffect prepareToDraw];
    
    // Clear back frame buffer (erase previous drawing)
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBindBuffer(GL_ARRAY_BUFFER,_Buffer);// STEP 2
    glEnableVertexAttribArray(GLKVertexAttribPosition);// Step 4
    // Step 5
    glVertexAttribPointer(GLKVertexAttribPosition,               // Identifies the attribute to use
                          3,               // number of coordinates for attribute
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          sizeof(SceneVertex),         // total num bytes stored per vertex
                          NULL + offsetof(SceneVertex, positionCoords));      // offset from start of each vertex to
                                               // first coord for attribute
    
    glBindBuffer(GL_ARRAY_BUFFER, _Buffer);// STEP 2
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);// Step 4
    // Step 5
    glVertexAttribPointer(GLKVertexAttribTexCoord0,               // Identifies the attribute to use
                          2,               // number of coordinates for attribute
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          sizeof(SceneVertex),         // total num bytes stored per vertex
                          NULL + offsetof(SceneVertex, textureCoords));      // offset from start of each vertex to first coord for attribute
    
    // Step 6
    // Draw triangles using the first three vertices in the
    // currently bound vertex buffer
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
}

#pragma mark -Action

- (IBAction)changeAction:(UIButton *)sender {
    NSInteger index = [picNameArr indexOfObject:picName];
    picName = [picNameArr objectAtIndex:(index + 1)%picNameArr.count];
    [self setTextureWithImage:picName];
}

- (void)updateVertex:(CGFloat)widthR heightR:(CGFloat)heightR{
//    {{-1.0f, -1.0f, 0.0f}, {0.0f, 0.0f}}, // lower left corner
//    {{ 1.0f, -1.0f, 0.0f}, {1.0f, 0.0f}}, // lower right corner
//    {{-1.0f,  1.0f, 0.0f}, {0.0f, 1.0f}}, // upper left corner
//    {{ 1.0f,  1.0f, 0.0f}, {1.0f, 1.0f}}, // upper right corner
    widthRatio = widthR;
    heightRatio = heightR;
    
    SceneVertex vertices1 = {{-widthRatio, -heightRatio, 0}, {1.0, 1.0}};
    vertices[0] = vertices1;
    
    SceneVertex vertices2 = {{ widthRatio, -heightRatio, 0}, {0.0, 1.0}};
    vertices[1] = vertices2;
    
    SceneVertex vertices3 = {{-widthRatio,  heightRatio, 0}, {1.0, 0.0}};
    vertices[2] = vertices3;
    
    SceneVertex vertices4 = {{ widthRatio,  heightRatio, 0}, {0.0, 0.0}};
    vertices[3] = vertices4;
    
    [self resetBuffer];
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
