//
//  ForthViewController.h
//  OpenGLReview
//
//  Created by Channe Sun on 2017/12/14.
//  Copyright © 2017年 HUST. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ForthViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UISlider *upSlider;
@property (weak, nonatomic) IBOutlet UISlider *bottomSlider;
@property (weak, nonatomic) IBOutlet UILabel *upLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;
@property (weak, nonatomic) IBOutlet UISwitch *leftSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rightSwitch;
@property (weak, nonatomic) IBOutlet UILabel *leftLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) IBOutlet UILabel *radiusLabel;
@property (weak, nonatomic) IBOutlet UISlider *radiusSlider;

@end
