//
//  ThirdViewController.h
//  OpenGLReview
//
//  Created by Channe Sun on 2017/12/8.
//  Copyright © 2017年 HUST. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThirdViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *openGLView;
@property (weak, nonatomic) IBOutlet UIImageView *testImageView;

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UISlider *saturationSlider;
@property (weak, nonatomic) IBOutlet UISlider *brightnessSlider;
@property (weak, nonatomic) IBOutlet UILabel *saturationLabel;
@property (weak, nonatomic) IBOutlet UILabel *brightnessLabel;
@property (weak, nonatomic) IBOutlet UISwitch *grayScaleSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *negationSwitch;

@end
