//
//  FifthViewController.h
//  OpenGLReview
//
//  Created by Channe Sun on 2018/1/3.
//  Copyright © 2018年 HUST. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FifthViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIButton *blurTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *changeBtn;
@property (weak, nonatomic) IBOutlet UISwitch *blurSwitch;
@property (weak, nonatomic) IBOutlet UISlider *blurSlider;
@property (weak, nonatomic) IBOutlet UILabel *blurLabel;
@end
