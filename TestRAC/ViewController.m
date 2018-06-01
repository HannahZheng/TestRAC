//
//  ViewController.m
//  TestRAC
//
//  Created by MXTH on 2018/5/23.
//  Copyright © 2018年 Hannah. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveObjC.h>
#import "TwoViewController.h"
#import <ReactiveObjC/RACReturnSignal.h>

@interface ViewController ()
    
    @property (weak, nonatomic) IBOutlet UIImageView *imgV;
    @property (weak, nonatomic) IBOutlet UITextField *accountTF;
    @property (weak, nonatomic) IBOutlet UITextField *passwordTF;
    @property (weak, nonatomic) IBOutlet UIButton *loginBtn;
    @property (weak, nonatomic) IBOutlet UILabel *stateLabel;
    
    
    
    @property (weak, nonatomic) IBOutlet UIButton *otherBtn;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) RACCommand *command;
    
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
    //RACScheduler:RAC中的队列，用GCD封装的。
    //RACUnit :表⽰stream不包含有意义的值,也就是看到这个，可以直接理解为nil.
    //RACEvent: 把数据包装成信号事件(signal event)。它主要通过RACSignal的-materialize来使用，然并卵。
    
   
    //bind
    // 假设想监听文本框的内容，并且在每次输出结果的时候，都在文本框的内容拼接一段文字“输出：”
    
    // 方式一:在返回结果后，拼接。
//    [self.accountTF.rac_textSignal subscribeNext:^(id x) {
//
//        NSLog(@"输出:%@",x);
//
//    }];
//
    // 方式二:在返回结果前，拼接，使用RAC中bind方法做处理。
   
    [[self.accountTF.rac_textSignal bind:^RACSignalBindBlock _Nonnull{
        // 什么时候调用:
        // block作用:表示绑定了一个信号.
        
        return ^RACSignal *(id value, BOOL *stop){
            // 什么时候调用block:当信号有新的值发出，就会来到这个block。
            // block作用:做返回值的处理
            // 做好处理，通过信号返回出去.
            return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
        };
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
}

- (void)baseUse{
    // 1.代替代理
    // 需求：自定义redView,监听红色view中按钮点击
    // 之前都是需要通过代理监听，给红色View添加一个代理属性，点击按钮的时候，通知代理做事情
    // rac_signalForSelector:把调用某个对象的方法的信息转换成信号，就要调用这个方法，就会发送信号。
    // 这里表示只要redV调用btnClick:,就会发出信号，订阅就好了。
    
    self.stateLabel.userInteractionEnabled = YES;
    
    //    [[self.stateLabel rac_signalForSelector:@selector(btnClick:)] subscribeNext:^(id x) {
    //        NSLog(@"点击红色按钮");
    //    }];
    
    // 2.KVO
    // 把监听redV的center属性改变转换成信号，只要值改变就会发送信号
    // observer:可以传入nil
    [[self.stateLabel rac_valuesAndChangesForKeyPath:@"text" options:NSKeyValueObservingOptionNew observer:self] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    }];
    
    // 3.监听事件
    // 把按钮点击事件转换为信号，点击按钮，就会发送信号
    [[self.otherBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        
        NSLog(@"按钮被点击了");
    }];
    
    // 4.代替通知
    // 把监听到的通知转换信号
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(id x) {
        NSLog(@"键盘弹出");
    }];
    
    // 5.监听文本框的文字改变
    [self.accountTF.rac_textSignal subscribeNext:^(id x) {
        
        NSLog(@"文字改变了%@",x);
    }];
    
    // 6.处理多个请求，都返回结果的时候，统一做处理.
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // 发送请求1
        [subscriber sendNext:@"发送请求1"];
        return nil;
    }];
    
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // 发送请求2
        [subscriber sendNext:@"发送请求2"];
        return nil;
    }];
    
    // 使用注意：几个信号，参数一的方法就几个参数，每个参数对应信号发出的数据。
    [self rac_liftSelector:@selector(updateUIWithR1:r2:) withSignalsFromArray:@[request1,request2]];
    
}
// 更新UI
- (void)updateUIWithR1:(id)data r2:(id)data1
{
    NSLog(@"更新UI%@  %@",data,data1);
}


- (void)relativeConnection{
    //RACMulticastConnection
    //用于当一个信号，被多次订阅时，为了保证创建信号时，避免多次调用创建信号中的block，造成副作用，可以使用这个类处理。
    //RACMulticastConnection通过RACSignal的-publish或者-muticast:方法创建.
    
    // 需求：假设在一个信号中发送请求，每次订阅一次都会发送请求，这样就会导致多次请求。
    // 解决：使用RACMulticastConnection就能解决.
    
    /*
     // RACMulticastConnection使用步骤:
     // 1.创建信号 + (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe
     // 2.创建连接 RACMulticastConnection *connect = [signal publish];
     // 3.订阅信号,注意：订阅的不在是之前的信号，而是连接的信号。 [connect.signal subscribeNext:nextBlock]
     // 4.连接 [connect connect]
     
     */
    
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        
        NSLog(@"发送请求");
        [subscriber sendNext:@1];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"接收数据1");
    }];
    [signal subscribeNext:^(id x) {
        
        NSLog(@"接收数据2");
        
    }];
    //运行结果，会执行两遍发送请求，也就是每次订阅都会发送一次请求
    
    
    // RACMulticastConnection:解决重复请求问题
    RACMulticastConnection *connect = [signal publish];
    [connect.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅者一信号");
    }];
    [connect.signal subscribeNext:^(id x) {
        
        NSLog(@"订阅者二信号");
        
    }];
    [connect connect];
}

- (void)relativeRACCommand{
    //RACCommand
    //RAC中用于处理事件的类，可以把事件如何处理,事件中的数据如何传递，包装到这个类中，他可以很方便的监控事件的执行过程。
    //1:创建command
    _command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        
        NSLog(@"执行命令");
        //请求回来的数据 当成signal
        // 创建空信号,必须返回信号
        //        return [RACSignal empty];
        
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            
            [subscriber sendNext:@"123"];
            
            //如果数据传递完毕，一定要调用sendCompleted,否则command永远处于执行中。
            //但是当 网络请求发生错误时，调用了 sendError，就不需要调用sendCompleted
            [subscriber sendCompleted];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"销毁了");
            }];
        }];
    }];
    
    
    //2:信号正在执行与否:监听命令是否执行完毕,默认会来一次，可以直接跳过，skip表示跳过第一次信号。
    [[_command.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
        
        if ([x boolValue] == YES) {
            // 正在执行
            NSLog(@"正在执行");
            
        }else{
            // 执行完成
            NSLog(@"执行完成");
        }
        
    }];
    
    //3:订阅RACCommand中的信号
    //// switchToLatest:用于signal of signals，获取signal of signals发出的最新信号,也就是可以直接拿到RACCommand中的信号
    [[_command.executionSignals switchToLatest] subscribeNext:^(id  _Nullable x) {
        
        NSLog(@"executionSignals == %@",x);
    }];
    
    //4:错误信号 //必须这么订阅才能拿到
    [_command.errors subscribeNext:^(NSError * _Nullable x) {
        
        NSLog(@"errors == %@",x);
        
    }];
    
    //重点
    //5:执行命令
    
    [_command execute:@"别闹"];
    
    /*
     总结：
     RACCommand使用步骤：
     1.创建 initWithSignalBlock
     2.signalBlock的返回值是RACSignal，因此在block中创建RACSignal，并作为block的返回值
     3.执行 execute
     
     // 二、RACCommand使用注意:
     // 1.signalBlock必须要返回一个信号，不能传nil.
     // 2.如果不想要传递信号，直接创建空的信号[RACSignal empty];
     // 3.RACCommand中信号如果数据传递完，必须调用[subscriber sendCompleted]，这时命令才会执行完毕，否则永远处于执行中。
     // 4.RACCommand需要被强引用，否则接收不到RACCommand中的信号，因此RACCommand中的信号是延迟发送的。
     
     
     RACCommand常用来做网络请求。
     
     
     */
}

#pragma mark RACSubject
- (void)replaceDelegate{
    @weakify(self);
    [[self.otherBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        TwoViewController *twoVC = [TwoViewController new];
        //设置代理信号
        twoVC.delegateSubject = [RACSubject subject];
        [twoVC.delegateSubject subscribeNext:^(id  _Nullable x) {
            
        }];
        [twoVC.delegateSubject subscribeNext:^(NSArray *x) {
            NSLog(@"点击了通知按钮");
            @strongify(self);
            self.accountTF.text = x[0];
            self.passwordTF.text = x[1];
            
        }];
        [self presentViewController:twoVC animated:YES completion:nil];
    }];
    
    
}

- (void)relativeRACSequence{
    //数组和字典遍历
    //RACSequence:RAC中的集合类，用于代替NSArray,NSDictionary,可以使用它来快速遍历数组和字典。
    //RACTuple:元组类,类似NSArray,用来包装值.
    
    //遍历数组
    NSArray *numbers = @[@1,@2,@3,@4];
    // 第一步: 把数组转换成集合RACSequence numbers.rac_sequence
    // 第二步: 把集合RACSequence转换RACSignal信号类,numbers.rac_sequence.signal
    // 第三步: 订阅信号，激活信号，会自动把集合中的所有值，遍历出来。
    [numbers.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    // 2.遍历字典,遍历出来的键值对会包装成RACTuple(元组对象)
    // rac_sequence注意点：调用subscribeNext，并不会马上执行nextBlock，而是会等一会。
    NSDictionary *dict = @{@"name":@"xmg",@"age":@18};
    [dict.rac_sequence.signal subscribeNext:^(RACTuple *x) {
        
        // 解包元组，会把元组的值，按顺序给参数里面的变量赋值
        RACTupleUnpack(NSString *key,NSString *value) = x;
        
        // 相当于以下写法
        //        NSString *key = x[0];
        //        NSString *value = x[1];
        
        NSLog(@"%@ %@",key,value);
        
    }];
}

- (void)relativeRACSubject{
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
}

- (void)relativeRACReplaySubject{
    
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
    
    [[self.accountTF.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        
        
        return [RACSignal return:[NSString stringWithFormat:@"+86-%@",value]];
    }] subscribeNext:^(id  _Nullable x) {
        
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


    
    
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.view endEditing:YES];
    
    self.name = [NSString stringWithFormat:@"%@+",self.name];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
