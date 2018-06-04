//
//  ViewModel.m
//  TestRAC
//
//  Created by MXTH on 2018/6/4.
//  Copyright © 2018年 Hannah. All rights reserved.
//

#import "ViewModel.h"

@implementation ViewModel


- (LoginModel *)model{
    if (_model == nil) {
        _model = [[LoginModel alloc] init];
    }
    
    return _model;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialBind];
    }
    return self;
}

- (void)initialBind{
    @weakify(self);
    //头像
    RAC(self.model, headImg) = [[RACObserve(self.model, account) map:^id _Nullable(id  _Nullable value) {
        UIImage *image = [UIImage imageNamed:value];
        if (image == nil) {
            image = [UIImage imageNamed:@"touxiang"];
        }
        return image;
    }] distinctUntilChanged];
    
    //登录按钮能否点击
    _enableSignal = [RACSignal combineLatest:@[RACObserve(self.model, account), RACObserve(self.model, password)] reduce:^id (NSString *account, NSString *password){
        return @(account.length && password.length);
    }];

    //state
    //什么时候选择使用RACSubject?
    //需要手动控制sendNext error completed
    self.stateSubject = [RACSubject subject];
    
    //登录时的网络请求
    _loginCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        NSLog(@"点击了登录");
        
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            
            // 模仿网络延迟
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                if ([self.model.password isEqualToString:@"123456"]) {
                    [subscriber sendNext:@"登录成功"];
                    
                    // 数据传送完毕，必须调用完成，否则命令永远处于执行状态
                    [subscriber sendCompleted];
                    
                    [self.stateSubject sendNext:@"登录成功"];
                }else{
                    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:400800 userInfo:@{@"key":@"登录请求失败"}];
                    [subscriber sendError:error];
                    
                    [self.stateSubject sendNext:@"登录成功"];
                }
                
               
            });
            
            return nil;
        }];
    }];
    
//    [_loginCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
//        if ([x isEqualToString:@"登录成功"]) {
//            NSLog(@"登录成功");
//
//        }
//    }];
    
    [[_loginCommand.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        if ([x isEqualToNumber:@(YES)]) {
            
            // 正在登录ing...
            // 用蒙版提示
//            [MBProgressHUD showMessage:@"正在登录..."];
            [self.stateSubject sendNext:@"正在登录..."];
            
        }else
        {
            // 登录成功
            // 隐藏蒙版
//            [MBProgressHUD hideHUD];
            
        }
        
    
    }];
    
    [_loginCommand.errors subscribeNext:^(NSError * _Nullable x) {
        NSLog(@"errors == %@",x);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.stateSubject sendNext:@"登录失败"];
        });
    }];
}


@end
