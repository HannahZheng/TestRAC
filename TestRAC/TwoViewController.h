//
//  TwoViewController.h
//  TestRAC
//
//  Created by MXTH on 2018/6/1.
//  Copyright © 2018年 Hannah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC.h>

@interface TwoViewController : UIViewController

@property (nonatomic, strong) RACSubject *delegateSubject;

@end
