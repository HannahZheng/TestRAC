//
//  TwoViewController.m
//  TestRAC
//
//  Created by MXTH on 2018/6/1.
//  Copyright © 2018年 Hannah. All rights reserved.
//

#import "TwoViewController.h"


@interface TwoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIImageView *imgV;
@property (weak, nonatomic) IBOutlet UITextField *accountTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;




@end

@implementation TwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
    @weakify(self);
    [[self.backBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    
    RACSignal *signalA = [self.accountTF rac_textSignal];
    RACSignal *signalB = [[self.passwordTF rac_textSignal] filter:^BOOL(NSString * _Nullable value) {
        @strongify(self);
        if (self.passwordTF.text.length > 5) {
            self.passwordTF.text = [self.passwordTF.text substringToIndex:5];
        }
        return value.length < 5;
    }];
    
    [[RACSignal combineLatest:@[signalA, signalB] reduce:^id (NSString *account,NSString *password){
        return @(account.length && password.length);
    }] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        self.resetBtn.enabled = x.integerValue;
    }];
    
    [[self.resetBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        NSLog(@"%@",x);
        @strongify(self);
        if (self.delegateSubject) {
            [self.delegateSubject sendNext:@[self.accountTF.text, self.passwordTF.text]];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
   
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.view endEditing:YES];
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
