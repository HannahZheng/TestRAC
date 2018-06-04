//
//  LoginModel.h
//  TestRAC
//
//  Created by MXTH on 2018/6/4.
//  Copyright © 2018年 Hannah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LoginModel : NSObject

@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) UIImage *headImg;

@property (nonatomic, copy) NSString *state;

@end
