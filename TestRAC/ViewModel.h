//
//  ViewModel.h
//  TestRAC
//
//  Created by MXTH on 2018/6/4.
//  Copyright © 2018年 Hannah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC.h>
#import "LoginModel.h"

@interface ViewModel : NSObject

@property (nonatomic, strong) LoginModel *model;
@property (nonatomic, strong) RACSubject *stateSubject;
@property (nonatomic, strong, readonly) RACSignal *enableSignal;
@property (nonatomic, strong, readonly) RACCommand *loginCommand;

@end
