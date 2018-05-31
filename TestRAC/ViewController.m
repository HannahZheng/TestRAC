//
//  ViewController.m
//  TestRAC
//
//  Created by MXTH on 2018/5/23.
//  Copyright © 2018年 Hannah. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveObjC.h>

@interface ViewController ()
    
    @property (weak, nonatomic) IBOutlet UIImageView *imgV;
    @property (weak, nonatomic) IBOutlet UITextField *accountTF;
    @property (weak, nonatomic) IBOutlet UITextField *passwordTF;
    @property (weak, nonatomic) IBOutlet UIButton *loginBtn;
    @property (weak, nonatomic) IBOutlet UILabel *stateLabel;
    
    
    
    @property (weak, nonatomic) IBOutlet UIButton *otherBtn;

@property (nonatomic, copy) NSString *name;
    
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
   //RACSubject
    
}

#pragma mark 基础使用
- (void)base{
    @weakify(self);
    //textField
    [self.accountTF.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.imgV.image = [UIImage imageNamed:x];
        if (self.imgV.image == nil) {
            self.imgV.image = [UIImage imageNamed:@"touxiang"];
        }
    }];
    
    //button
    [[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        
    }];
    
    
    //定时器
    [[RACSignal interval:1 onScheduler:[RACScheduler scheduler]] subscribeNext:^(NSDate * _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //手势
    UITapGestureRecognizer *tap = [UITapGestureRecognizer new];
    self.stateLabel.userInteractionEnabled = YES;
    [self.stateLabel addGestureRecognizer:tap];
    [[tap rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //通知
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardDidChangeFrameNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //KVO
    [RACObserve(self, name) subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    self.name = @"Cooci";

}

- (void)upgrade{
    [self.loginBtn setBackgroundColor:[UIColor darkGrayColor]];
    
    @weakify(self);  //textField
    [self.accountTF.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.imgV.image = [UIImage imageNamed:x];
        if (self.imgV.image == nil) {
            self.imgV.image = [UIImage imageNamed:@"touxiang"];
        }
    }];
    
    //button
    [[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        
        if (![self.passwordTF.text isEqualToString:@"123"]) {
            self.stateLabel.text = @"密码错误，请重新输入...";
        }else{
            self.stateLabel.text = @"登录成功";
            [self.view endEditing:YES];
        }
        
    }];
    
    
    
    //map  flattenMap
    //实际应用时 通常会跳过第一次
    [[[self.accountTF.rac_textSignal skip:1] flattenMap:^__kindof RACSignal * _Nullable(NSString * _Nullable value) {
        
        return [RACSignal return:[NSString stringWithFormat:@"+86-%@",value]];
        
    }]  subscribeNext:^(id  _Nullable x) {
        NSLog(@"flattenMap  ===  %@",x);
    }];
    
    
    //filter
    [[[self.passwordTF.rac_textSignal skip:1] filter:^BOOL(NSString * _Nullable value) {
        //做过滤条件
        @strongify(self);
        if (self.passwordTF.text.length > 5) {
            self.passwordTF.text = [self.passwordTF.text substringToIndex:5];
            self.stateLabel.text = @"密码长度不能大于5";
        }
        return value.length < 5;
        
    }] subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"我订阅到了什么:%@",x);
        //逻辑区域
    }] ;
    
    
    //组合 combineLaster
    RACSignal *signalA = self.accountTF.rac_textSignal;
    RACSignal *signalB = self.passwordTF.rac_textSignal;
    
    [[RACSignal combineLatest:@[signalA, signalB] reduce:^id (NSString *account,NSString *password){
        //reduceBlock的参数个数 要与 合并的信号数组的个数保持一致
        //此处 可以将多个参数合并
        return @(account.length && password.length);
    }] subscribeNext:^(NSNumber *x) {
        self.loginBtn.backgroundColor = x.integerValue ? [UIColor greenColor] : [UIColor darkGrayColor];
        self.loginBtn.enabled = x.integerValue;
    }];
    
    //takeUntil
    //subject1 正常发送，直到subject2发送信号。意味着subject2发送信号后 subject1不能再发送信号
    //以下代码，reboot不能正常发送，除非注释掉 [subject2 sendNext:@"hani"];
    
    RACSubject *subject1 = [RACSubject subject];
    RACSubject *subject2 = [RACSubject subject];
    
    [[subject1 takeUntil:subject2] subscribeNext:^(id  _Nullable x) {
        
        NSLog(@"%@",x);
    }];
    
    [subject1 sendNext:@"菲尼克斯"];
    [subject1 sendNext:@"艾拇"];
    
    [subject2 sendNext:@"hani"];
    
    [subject1 sendNext:@"reboot"];

}

- (void)test:(void(^)(NSString *))block{
    
    block = ^(NSString *name){
    };
}


- (void)baseInfo{
    
}
    
    
    
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.view endEditing:YES];
    
    self.name = [NSString stringWithFormat:@"%@+",self.name];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
