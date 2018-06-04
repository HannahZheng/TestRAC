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
#import "ViewModel.h"

@interface ViewController ()
    
    @property (weak, nonatomic) IBOutlet UIImageView *imgV;
    @property (weak, nonatomic) IBOutlet UITextField *accountTF;
    @property (weak, nonatomic) IBOutlet UITextField *passwordTF;
    @property (weak, nonatomic) IBOutlet UIButton *loginBtn;
    @property (weak, nonatomic) IBOutlet UILabel *stateLabel;
    
    
    
    @property (weak, nonatomic) IBOutlet UIButton *otherBtn;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) RACCommand *command;

@property (nonatomic, strong) ViewModel *viewModel;
    
@end

@implementation ViewController


- (ViewModel *)viewModel{
    if (_viewModel == nil) {
        _viewModel = [ViewModel new];
    }
    
    return _viewModel;
}

- (void)bindModel{
    RAC(self.viewModel.model, account) = _accountTF.rac_textSignal;
    RAC(self.viewModel.model, password) = _passwordTF.rac_textSignal;
    RAC(self.loginBtn, enabled) = self.viewModel.enableSignal;
    RAC(self.stateLabel, text) = self.viewModel.stateSubject;
    
    @weakify(self);
    [RACObserve(self.viewModel.model, headImg) subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.imgV.image = x;
    }];
    
    
    
    [[_loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        [self.viewModel.loginCommand execute:nil];
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    

    
    [self bindModel];
    
}



- (void)detail{
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
    
    //所有的信号（RACSignal）都可以进行操作处理，因为所有操作方法都定义在RACStream.h中，因此只要继承RACStream就有了操作处理方法
    
    
    
    /* ReactiveCocoa操作方法之秩序。
     doNext: 执行Next之前，会先执行这个Block
     doCompleted: 执行sendCompleted之前，会先执行这个Block
     
     */
    
    [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@123];
        [subscriber sendCompleted];
        return nil;
    }] doNext:^(id x) {
        // 执行[subscriber sendNext:@1];之前会调用这个Block
        NSLog(@"doNext");;
    }] doCompleted:^{
        // 执行[subscriber sendCompleted];之前会调用这个Block
        NSLog(@"doCompleted");;
        
    }] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    /*
     ReactiveCocoa操作方法之线程。
     
     deliverOn: 内容传递切换到制定线程中，副作用在原来线程中,把在创建信号时block中的代码称之为副作用。
     
     subscribeOn: 内容传递和副作用都会切换到制定线程中。
     */
}

- (void)repeat{
    //retry重试 ：只要失败，就会重新执行创建信号中的block,直到成功.
    
    __block int i = 0;
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        if (i == 10) {
            [subscriber sendNext:@1];
        }else{
            NSLog(@"接收到错误");
            [subscriber sendError:nil];
        }
        i++;
        
        return nil;
        
    }] retry] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    } error:^(NSError *error) {
        
        
    }];
    
   //`replay`重放：当一个信号被多次订阅,反复播放内容
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        
        [subscriber sendNext:@1];
        [subscriber sendNext:@2];
        
        return nil;
    }] replay];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"第一个订阅者%@",x);
        
    }];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"第二个订阅者%@",x);
        
    }];
    
  //throttle节流:当某个信号发送比较频繁时，可以使用节流，在某一段时间不发送信号内容，过了一段时间获取信号的最新内容发出。
    
    RACSubject *signalT = [RACSubject subject];
    // 节流，在一定时间（1秒）内，不接收任何信号内容，过了这个时间（1秒）获取最后发送的信号内容发出。
    [[signalT throttle:1] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];

}

- (void)time{
    //timeout：超时，可以让一个信号在一定的时间后，自动报错。
    
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return nil;
    }] timeout:1 onScheduler:[RACScheduler currentScheduler]];
    
    [signal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    } error:^(NSError *error) {
        // 1秒后会自动调用
        NSLog(@"%@",error);
    }];
    
    //interval 定时：每隔一段时间发出信号
    [[RACSignal interval:1 onScheduler:[RACScheduler currentScheduler]] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //delay 延迟发送next。
    RACSignal *signal2 = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        return nil;
    }] delay:2] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
}

- (void)other{
    //filter:过滤信号，使用它可以获取满足条件的信号.
    // 过滤:
    // 每次信号发出，会先执行过滤条件判断.
    [[_accountTF.rac_textSignal filter:^BOOL(NSString *value) {
        return value.length > 3;
    }] subscribeNext:^(NSString * _Nullable x) {
        
    }];
    
    
    //ignore:忽略完某些值的信号.
    // 内部调用filter过滤，忽略掉ignore的值
    [[_accountTF.rac_textSignal ignore:@"1"] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //distinctUntilChanged:当上一次的值和当前的值有明显的变化就会发出信号，否则会被忽略掉。
    
    // 过滤，当上一次和当前的值不一样，就会发出内容。
    // 在开发中，刷新UI经常使用，只有两次数据不一样才需要刷新
    [[_accountTF.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    
    //take:从开始一共取N次的信号
//    // 1、创建信号
//    RACSubject *signal = [RACSubject subject];
//
//    // 2、处理信号，订阅信号
//    [[signal take:1] subscribeNext:^(id x) {
//
//        NSLog(@"%@",x);
//    }];
//
//    // 3.发送信号
//    [signal sendNext:@1];
//
//    [signal sendNext:@2];
//

    //takeLast:取最后N次的信号,前提条件，订阅者必须调用完成，因为只有完成，才知道总共有多少信号.
    // 1、创建信号
//    RACSubject *signal = [RACSubject subject];
//
//    // 2、处理信号，订阅信号
//    [[signal takeLast:1] subscribeNext:^(id x) {
//
//        NSLog(@"%@",x);
//    }];
//
//    // 3.发送信号
//    [signal sendNext:@1];
//
//    [signal sendNext:@2];
//
//    [signal sendCompleted];
  
    
    //takeUntil:(RACSignal *):获取信号直到某个信号执行完成
    // 监听文本框的改变直到当前对象被销毁
    [_accountTF.rac_textSignal takeUntil:self.rac_willDeallocSignal];

    //skip:(NSUInteger):跳过几个信号,不接受。
    // 表示输入第一次，不会被监听到，跳过第一次发出的信号
    [[_accountTF.rac_textSignal skip:1] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    //switchToLatest:用于signalOfSignals（信号的信号），有时候信号也会发出信号，会在signalOfSignals中，获取signalOfSignals发送的最新信号。
    RACSubject *signalOfSignals = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    
    // 获取信号中信号最近发出信号，订阅最近发出的信号。
    // 注意switchToLatest：只能用于信号中的信号
    [signalOfSignals.switchToLatest subscribeNext:^(id x) {
        
        NSLog(@"signalOfSignals: %@",x);
    }];
    
      [signalOfSignals sendNext:signal];
     [signal sendNext:@1];
  

    

}

- (void)reduce{
    //`reduce`聚合:用于信号发出的内容是元组，把信号发出元组的值聚合成一个值
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    // 聚合
    // 常见的用法，（先组合在聚合）。combineLatest:(id<NSFastEnumeration>)signals reduce:(id (^)())reduceBlock
    // reduce中的block简介:
    // reduceblcok中的参数，有多少信号组合，reduceblcok就有多少参数，每个参数就是之前信号发出的内容
    // reduceblcok的返回值：聚合信号之后的内容。
    RACSignal *reduceSignal = [RACSignal combineLatest:@[signalA,signalB] reduce:^id(NSNumber *num1 ,NSNumber *num2){
        
        return [NSString stringWithFormat:@"%@ %@",num1,num2];
        
    }];
    
    [reduceSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    // 底层实现:
    // 1.订阅聚合信号，每次有内容发出，就会执行reduceblcok，把信号内容转换成reduceblcok返回的值。
    

    //
}

- (void)combineLatest{
    //combineLatest:将多个信号合并起来，并且拿到各个信号的最新的值,必须每个合并的signal至少都有过一次sendNext，才会触发合并的信号。
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    // 把两个信号组合成一个信号,跟zip一样，没什么区别
    RACSignal *combineSignal = [signalA combineLatestWith:signalB];
    
    [combineSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    

}

- (void)zip{
    //zipWith:把两个信号压缩成一个信号，只有当两个信号同时发出信号内容时，并且把两个信号的内容合并成一个元组，才会触发压缩流的next事件。
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    
    
    // 压缩信号A，信号B
    RACSignal *zipSignal = [signalA zipWith:signalB];
    
    [zipSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    // 底层实现:
    // 1.定义压缩信号，内部就会自动订阅signalA，signalB
    // 2.每当signalA或者signalB发出信号，就会判断signalA，signalB有没有发出个信号，有就会把最近发出的信号都包装成元组发出。

}

- (void)merge{
    //`merge`:把多个信号合并为一个信号，任何一个信号有新值的时候就会调用
    // merge:把多个信号合并成一个信号
    //创建多个信号
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        
        return nil;
    }];
    
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    // 合并信号,任何一个信号发送数据，都能监听到.
    RACSignal *mergeSignal = [signalA merge:signalB];
    
    [mergeSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    }];
    
    // 底层实现：
    // 1.合并信号被订阅的时候，就会遍历所有信号，并且发出这些信号。
    // 2.每发出一个信号，这个信号就会被订阅
    // 3.也就是合并信号一被订阅，就会订阅里面所有的信号。
    // 4.只要有一个信号被发出就会被监听。

}

- (void)then{
    // then:用于连接两个信号，当第一个信号完成，才会连接then返回的信号
    // 注意使用then，之前信号的值会被忽略掉.
    // 底层实现：1、先过滤掉之前的信号发出的值。2.使用concat连接then返回的信号
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        [subscriber sendCompleted];
        return nil;
    }] then:^RACSignal *{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@2];
            return nil;
        }];
    }] subscribeNext:^(id x) {
        
        // 只能接收到第二个信号的值，也就是then返回信号的值
        NSLog(@"%@",x);
    }];
    
    
}

- (void)concat{
    //concat:按一定顺序拼接信号，当多个信号发出的时候，有顺序的接收信号。
    
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@1];
        
        [subscriber sendCompleted];
        
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@2];
        
        return nil;
    }];
    
    // 把signalA拼接到signalB后，signalA发送完成，signalB才会被激活。
    RACSignal *concatSignal = [signalA concat:signalB];
    
    // 以后只需要面对拼接信号开发。
    // 订阅拼接的信号，不需要单独订阅signalA，signalB
    // 内部会自动订阅。
    // 注意：第一个信号必须发送完成，第二个信号才会被激活
    [concatSignal subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    }];
    
    // concat底层实现:
    // 1.当拼接信号被订阅，就会调用拼接信号的didSubscribe
    // 2.didSubscribe中，会先订阅第一个源信号（signalA）
    // 3.会执行第一个源信号（signalA）的didSubscribe
    // 4.第一个源信号（signalA）didSubscribe中发送值，就会调用第一个源信号（signalA）订阅者的nextBlock,通过拼接信号的订阅者把值发送出来.
    // 5.第一个源信号（signalA）didSubscribe中发送完成，就会调用第一个源信号（signalA）订阅者的completedBlock,订阅第二个源信号（signalB）这时候才激活（signalB）。
    // 6.订阅第二个源信号（signalB）,执行第二个源信号（signalB）的didSubscribe
    // 7.第二个源信号（signalA）didSubscribe中发送值,就会通过拼接信号的订阅者把值发送出来.
    
   
}

- (void)map{
    //flattenMap，Map用于把源信号内容映射成新的内容。
    //flattenMap内部调用bind方法实现的,flattenMap中block的返回值，会作为bind中bindBlock的返回值。
    [[self.accountTF.rac_textSignal flattenMap:^__kindof RACSignal * _Nullable(NSString * _Nullable value) {
        return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
    }] subscribeNext:^(id  _Nullable x) {
        // 订阅绑定信号，每当源信号发送内容，做完处理，就会调用这个block。
        
        NSLog(@"%@",x);
    }];
    
    //Map底层其实是调用flatternMap,Map中block中的返回的值会作为flatternMap中block中的值。
    // 1.当订阅绑定信号，就会生成bindBlock。
    // 3.当源信号发送内容，就会调用bindBlock(value, *stop)
    // 4.调用bindBlock，内部就会调用flattenMap的block
    // 5.flattenMap的block内部会调用Map中的block，把Map中的block返回的内容包装成返回的信号。
    // 5.返回的信号最终会作为bindBlock中的返回信号，当做bindBlock的返回信号。
    // 6.订阅bindBlock的返回信号，就会拿到绑定信号的订阅者，把处理完成的信号内容发送出来。
    

    [[_accountTF.rac_textSignal map:^id(id value) {
        // 当源信号发出，就会调用这个block，修改源信号的内容
        // 返回值：就是处理完源信号的内容。
        return [NSString stringWithFormat:@"输出:+008 %@",value];
    }] subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
    }];
    
    /*
     FlatternMap和Map的区别
     
     1.FlatternMap中的Block返回信号。
     2.Map中的Block返回对象。
     3.开发中，如果信号发出的值不是信号，映射一般使用Map
     4.开发中，如果信号发出的值是信号，映射一般使用FlatternMap。
     总结：signalOfsignals用FlatternMap。
     

     */
    
    
    // 创建信号中的信号
    RACSubject *signalOfsignals = [RACSubject subject];
    RACSubject *signal = [RACSubject subject];
    
    [[signalOfsignals flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        
        return value;
    }] subscribeNext:^(id x) {
        
        // 只有signalOfsignals的signal发出信号才会调用，因为内部订阅了bindBlock中返回的信号，也就是flattenMap返回的信号。
        // 也就是flattenMap返回的信号发出内容，才会调用。
        
        NSLog(@"%@aaa",x);
    }];
    
    // 信号的信号发送信号
    [signalOfsignals sendNext:signal];
    
    // 信号发送内容
    [signal sendNext:@1];
    

    
}

- (void)bind{
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
        
        /*
         * -bind: should:
         *
         * 1. Subscribe to the original signal of values.
         * 2. Any time the original signal sends a value, transform it using the binding block.
         * 3. If the binding block returns a signal, subscribe to it, and pass all of its values through to the subscriber as they're received.
         * 4. If the binding block asks the bind to terminate, complete the _original_ signal.
         * 5. When _all_ signals complete, send completed to the subscriber.
         *
         * If any signal sends an error at any point, send that to the subscriber.
         */
        
        
        // RACStreamBindBlock:
        // 参数一(value):表示接收到信号的原始值，还没做处理
        // 参数二(*stop):用来控制绑定Block，如果*stop = yes,那么就会结束绑定。
        // 返回值：信号，做好处理，在通过这个信号返回出去，一般使用RACReturnSignal,需要手动导入头文件RACReturnSignal.h。
        
        
        return ^RACSignal *(id value, BOOL *stop){
            // 什么时候调用block:当信号有新的值发出，就会来到这个block。
            // block作用:做返回值的处理
            // 做好处理，通过信号返回出去.
            return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@",value]];
        };
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    /*
     bind的底层实现：
     调用bind，会重新创建一个绑定信号；
     绑定信号的didSubcribe会被保存起来；
     当绑定信号被订阅，就会调用绑定信号的didSubcribe，在didSubscribe中，会生成一个RACSignalBindBlock；
     当源信号有内容发出，就会将内容传递给bindingBlock处理，在bindingBlock中，会返回一个内容处理完成的信号；
     
     这个内容处理完成的信号RACReturnSignal，会将处理完成的信号发送出来，订阅者会接收这个新值。
     
     - (RACSignal *)bind:(RACSignalBindBlock (^)(void))block {
     NSCParameterAssert(block != NULL);
     
     /
     * -bind: should:
     *
     * 1. Subscribe to the original signal of values.
     * 2. Any time the original signal sends a value, transform it using the binding block.
     * 3. If the binding block returns a signal, subscribe to it, and pass all of its values through to the subscriber as they're received.
     * 4. If the binding block asks the bind to terminate, complete the _original_ signal.
     * 5. When _all_ signals complete, send completed to the subscriber.
     *
     * If any signal sends an error at any point, send that to the subscriber.
     /
     
     return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
     RACSignalBindBlock bindingBlock = block();
     
     __block volatile int32_t signalCount = 1;   // indicates self
     
     RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
     
     void (^completeSignal)(RACDisposable *) = ^(RACDisposable *finishedDisposable) {
     if (OSAtomicDecrement32Barrier(&signalCount) == 0) {
     [subscriber sendCompleted];
     [compoundDisposable dispose];
     } else {
     [compoundDisposable removeDisposable:finishedDisposable];
     }
     };
     
     void (^addSignal)(RACSignal *) = ^(RACSignal *signal) {
     OSAtomicIncrement32Barrier(&signalCount);
     
     RACSerialDisposable *selfDisposable = [[RACSerialDisposable alloc] init];
     [compoundDisposable addDisposable:selfDisposable];
     
     RACDisposable *disposable = [signal subscribeNext:^(id x) {
     [subscriber sendNext:x];
     } error:^(NSError *error) {
     [compoundDisposable dispose];
     [subscriber sendError:error];
     } completed:^{
     @autoreleasepool {
     completeSignal(selfDisposable);
     }
     }];
     
     selfDisposable.disposable = disposable;
     };
     
     @autoreleasepool {
     RACSerialDisposable *selfDisposable = [[RACSerialDisposable alloc] init];
     [compoundDisposable addDisposable:selfDisposable];
     
     RACDisposable *bindingDisposable = [self subscribeNext:^(id x) {
     // Manually check disposal to handle synchronous errors.
     if (compoundDisposable.disposed) return;
     
     BOOL stop = NO;
     id signal = bindingBlock(x, &stop);
     
     @autoreleasepool {
     if (signal != nil) addSignal(signal);
     if (signal == nil || stop) {
     [selfDisposable dispose];
     completeSignal(selfDisposable);
     }
     }
     } error:^(NSError *error) {
     [compoundDisposable dispose];
     [subscriber sendError:error];
     } completed:^{
     @autoreleasepool {
     completeSignal(selfDisposable);
     }
     }];
     
     selfDisposable.disposable = bindingDisposable;
     }
     
     return compoundDisposable;
     }] setNameWithFormat:@"[%@] -bind:", self.name];
     }
     
     
     */
    
    
    /*
     RACReturnSignal 同步发送值给订阅者，并发送完成
     
     - (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
     NSCParameterAssert(subscriber != nil);
     
     return [RACScheduler.subscriptionScheduler schedule:^{
     [subscriber sendNext:self.value];
     [subscriber sendCompleted];
     }];
     }
     */
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
