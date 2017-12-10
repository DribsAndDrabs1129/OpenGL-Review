//
//  SecondViewController.h
//  OpenGLReview
//
//  Created by Channe Sun on 2017/12/8.
//  Copyright © 2017年 HUST. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "AGLKVertexAttribArrayBuffer.h"

@interface SecondViewController : GLKViewController

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexBuffer;

@end
