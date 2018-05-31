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
    
//    RACSubscriber 订阅者，用于发送信号，这是一个协议
    /*
     RACSubscriber协议有4个必须实现的方法：
     - (void)sendNext:(nullable id)value;
     - (void)sendError:(nullable NSError *)error;
     - (void)sendCompleted;
     - (void)didSubscribeWithDisposable:(RACCompoundDisposable *)disposable;
     
     */
    //RACDisposable:用于取消订阅或者清理资源，当信号发送完成或者发送错误的时候，就会自动触发它。
    
    
   //RACSubject
    //是RACSignal的子类，因此可以充当信号，但同时它还能发送信号
    //RACReplaySubject
   
    /*
     使用步骤类似与RACSignal：
     1.创建信号 [RACSubject subject]
     2.订阅信号 - (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock
     3.发送信号 sendNext:(id)value
     
     但它的底层实现与RACSignal不一样。
     
     */
    
    RACSubject *subject = [RACSubject subject];
    [subject subscribeNext:^(id  _Nullable x) {
        // block调用时刻：当信号发出新值，就会调用.
        NSLog(@"第一个订阅者%@",x);
    }];
    [subject subscribeNext:^(id  _Nullable x) {
        // block调用时刻：当信号发出新值，就会调用.
        NSLog(@"第二个订阅者%@",x);
    }];
    [subject sendNext:@"1"];
    
    
    /*
     源码分析
     1.subject创建时，在创建RACCompoundDisposable的同时，还创建了一个订阅者数组。
     - (instancetype)init {
     self = [super init];
     if (self == nil) return nil;
     
     _disposable = [RACCompoundDisposable compoundDisposable];
     _subscribers = [[NSMutableArray alloc] initWithCapacity:1];
     
     return self;
     }
     2.subscribeNext调用时，除了创建订阅者，及 将nextBlock保存起来，同时会将创建的订阅者添加到订阅者数组中。
     
     - (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock {
     NSCParameterAssert(nextBlock != NULL);
     
     RACSubscriber *o = [RACSubscriber subscriberWithNext:nextBlock error:NULL completed:NULL];
     return [self subscribe:o];
     }
     
     
     + (instancetype)subscriberWithNext:(void (^)(id x))next error:(void (^)(NSError *error))error completed:(void (^)(void))completed {
     RACSubscriber *subscriber = [[self alloc] init];
     
     subscriber->_next = [next copy];
     subscriber->_error = [error copy];
     subscriber->_completed = [completed copy];
     
     return subscriber;
     }
     
     #pragma mark Subscription
     
     - (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
     NSCParameterAssert(subscriber != nil);
     
     RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
     subscriber = [[RACPassthroughSubscriber alloc] initWithSubscriber:subscriber signal:self disposable:disposable];
     
     NSMutableArray *subscribers = self.subscribers;
     @synchronized (subscribers) {
     [subscribers addObject:subscriber];
     }
     
     [disposable addDisposable:[RACDisposable disposableWithBlock:^{
     @synchronized (subscribers) {
     // Since newer subscribers are generally shorter-lived, search
     // starting from the end of the list.
     NSUInteger index = [subscribers indexOfObjectWithOptions:NSEnumerationReverse passingTest:^ BOOL (id<RACSubscriber> obj, NSUInteger index, BOOL *stop) {
     return obj == subscriber;
     }];
     
     if (index != NSNotFound) [subscribers removeObjectAtIndex:index];
     }
     }]];
     
     return disposable;
     }
     
     3.sendNext 发送信号，会遍历subject所有的订阅者，并依次调用订阅者的nextBlock
     
     
     - (void)sendNext:(id)value {
     [self enumerateSubscribersUsingBlock:^(id<RACSubscriber> subscriber) {
     [subscriber sendNext:value];
     }];
     }
     
     - (void)enumerateSubscribersUsingBlock:(void (^)(id<RACSubscriber> subscriber))block {
     NSArray *subscribers;
     @synchronized (self.subscribers) {
     subscribers = [self.subscribers copy];
     }
     
     for (id<RACSubscriber> subscriber in subscribers) {
     block(subscriber);
     }
     }
     
     
     #pragma mark RACSubscriber
     
     - (void)sendNext:(id)value {
     @synchronized (self) {
     void (^nextBlock)(id) = [self.next copy];
     if (nextBlock == nil) return;
     
     nextBlock(value);
     }
     }
     
     */
    
    
    //RACReplaySubject
    //是RACSubject的子类，但它可以先订阅信号，也可以先发送信号。
    //如果 一个信号被订阅，就会重复播放之前的所有值，那就要先发送信号，再订阅信号。
    // 1.创建信号
    RACReplaySubject *replaySubject = [RACReplaySubject subject];
    
    // 2.发送信号
    [replaySubject sendNext:@1];
    [replaySubject sendNext:@2];
    
    // 3.订阅信号
    [replaySubject subscribeNext:^(id x) {
        
        NSLog(@"第一个订阅者接收到的数据%@",x);
    }];
    
    // 订阅信号
    [replaySubject subscribeNext:^(id x) {
        
        NSLog(@"第二个订阅者接收到的数据%@",x);
    }];
    
    /*
     底层分析：
     1.创建信号，与RACSubject一样
     2.sendNext发送信号，不同于RACSubject.会将发送的信号添加到值接收的数组中去，然后再遍历所有的订阅者，依次调用订阅者的nextBlock
     
     - (void)sendNext:(id)value {
     @synchronized (self) {
     [self.valuesReceived addObject:value ?: RACTupleNil.tupleNil];
     [super sendNext:value];
     
     if (self.capacity != RACReplaySubjectUnlimitedCapacity && self.valuesReceived.count > self.capacity) {
     [self.valuesReceived removeObjectsInRange:NSMakeRange(0, self.valuesReceived.count - self.capacity)];
     }
     }
     }
     
     3.subscribeNex订阅信号时，除创建订阅者，保存nextBlock，将订阅者添加到订阅者数组中去 这些操作之外，还会遍历replaySubject的valuesReceived数组（该数组中保存的是发送的信号值），依次将这些值再发送一次
     
     
     - (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock {
     NSCParameterAssert(nextBlock != NULL);
     
     RACSubscriber *o = [RACSubscriber subscriberWithNext:nextBlock error:NULL completed:NULL];
     return [self subscribe:o];
     }
     
     
     + (instancetype)subscriberWithNext:(void (^)(id x))next error:(void (^)(NSError *error))error completed:(void (^)(void))completed {
     RACSubscriber *subscriber = [[self alloc] init];
     
     subscriber->_next = [next copy];
     subscriber->_error = [error copy];
     subscriber->_completed = [completed copy];
     
     return subscriber;
     }
     
     #pragma mark RACSignal
     
     - (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
     RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
     
     RACDisposable *schedulingDisposable = [RACScheduler.subscriptionScheduler schedule:^{
     @synchronized (self) {
     for (id value in self.valuesReceived) {
     if (compoundDisposable.disposed) return;
     
     [subscriber sendNext:(value == RACTupleNil.tupleNil ? nil : value)];
     }
     
     if (compoundDisposable.disposed) return;
     
     if (self.hasCompleted) {
     [subscriber sendCompleted];
     } else if (self.hasError) {
     [subscriber sendError:self.error];
     } else {
     RACDisposable *subscriptionDisposable = [super subscribe:subscriber];
     [compoundDisposable addDisposable:subscriptionDisposable];
     }
     }
     }];
     
     [compoundDisposable addDisposable:schedulingDisposable];
     
     return compoundDisposable;
     }
     
     */
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
