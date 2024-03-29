//
//  ViewController.m
//  LearnNode
//
//  Created by Lechech on 2021/3/12.
//

#import "ViewController.h"
#import "Person.h"
@interface ViewController ()

@property (nonatomic,copy) NSString *name;
@property (nonatomic,assign) int age;
//@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,assign) BOOL isMainThreadExit;

@property (nonatomic,strong)NSArray *array;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //消费者生产模式
//    [self produceDemo];
    
    
    //===============================
    
    
    
    //线程与队列
//    [self threadAndQueue];
    
    
    //=================================
    
    
    
    
    //线程与内存
//    [self threadAndMemory];
    
    
    //=================================
    
    
    
    //block循环引用
    
    
    //=================================

    
    //信号量
//    [self semaphore];
    
    
    
    //死锁
//    [self deadLock];

    
    //深、浅拷贝
//    [self shallowAndDeepCopy];
    
    
    
    //自动释放池
//    [self autoreleasepool];
    
    
    
    
    
    //定时器
    [self timer];
}





/*
 消费者生产模式代码实现
 
 */
- (void)produceDemo{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //假设五秒后退出生产、消费
        self.isMainThreadExit = YES;
    });
    
    //缓冲区（仓库）
    __block int numberCount = 0;

    //生产速度
    float produceTimePer = 0.1;

    //消费速度
    float consumerTimePerB = 1;
    
    //消费速度
    float consumerTimePerC = 3;
    
    //交易锁，防止同一时间出现两笔消费，或者一笔消费过程中有生产干扰，引起数据混乱
    NSLock *lock = [[NSLock alloc] init];

    //A线程，生产100个货品，生产的货品放入仓库中
    NSOperationQueue *produceQueue = [[NSOperationQueue alloc] init];
    produceQueue.maxConcurrentOperationCount = 1;

    [produceQueue addOperationWithBlock:^{
        do {
            usleep(produceTimePer * USEC_PER_SEC);
            [lock lock];
            numberCount++;
            printf("A线程生产了1个，当前仓库个数%d\n",numberCount);
            [lock unlock];
        } while (!self.isMainThreadExit);
    }];


    //B线程
    NSOperationQueue *consumerQueueB = [[NSOperationQueue alloc] init];
    consumerQueueB.maxConcurrentOperationCount = 1;

    [consumerQueueB addOperationWithBlock:^{
        
        do {
            usleep(consumerTimePerB * USEC_PER_SEC);
            [lock lock];
            if (numberCount > 0) {
                numberCount--;
                printf("B线程消费了1个,剩余个数%d\n",numberCount);
            }
            [lock unlock];
        } while (!self.isMainThreadExit);
        
    }];
    
    //C线程
    NSOperationQueue *consumerQueueC = [[NSOperationQueue alloc] init];
    consumerQueueC.maxConcurrentOperationCount = 1;

    [consumerQueueC addOperationWithBlock:^{
        
        do {
            usleep(consumerTimePerC * USEC_PER_SEC);
            [lock lock];
            if (numberCount > 0) {
                numberCount--;
                printf("C线程消费了1个,剩余个数%d\n",numberCount);
            }
            [lock unlock];
        } while (!self.isMainThreadExit);
        
    }];
        
}




/*
 线程与队列
 */
- (void)threadAndQueue {
    
    
    //问：以下几个方法有什么区别？
    
//    dispatch_queue_t global_queue = dispatch_get_global_queue(0, 0);
//    for (NSInteger i = 0; i < 100; i++) {
//        dispatch_async(global_queue, ^{
//            NSLog(@" i:%ld，currentThread:%@",(long)i,[NSThread currentThread]);
//            usleep(0.1 * USEC_PER_SEC);
//        });
//    }
//    解析：向全局队列global_queue里插入了100个任务,系统会创建100次子线程，但是不是同时创建100个子线程，因为GCD
//    会控制最大并发数。整体上，打印的数值是递增的，但是因为每次都是由n个线程同时执行，所以这n个线程的打印顺序是错乱的。
//    如果是通过dispatch_block_t创建的blcok任务，未执行到的block可以被取消。
    
    
    
//    dispatch_queue_t global_queue = dispatch_get_global_queue(0, 0);
//    dispatch_async(global_queue, ^{
//        for (NSInteger i = 0; i < 100; i++) {
//            NSLog(@" i:%ld，currentThread:%@",(long)i,[NSThread currentThread]);
//            usleep(0.1 * USEC_PER_SEC);
//        }
//    });
//    解析：向全局队列global_queue里插入了1个block任务,系统会创建一个子线程，去执行这1个block任务。这个任务是依次打印i的值。
//

    
    
//    dispatch_queue_t serial_queue = dispatch_queue_create("threadAndQueue", DISPATCH_QUEUE_SERIAL);
//    for (NSInteger i = 0; i < 100; i++) {
//        dispatch_async(serial_queue, ^{
//            NSLog(@" i:%ld，currentThread:%@",(long)i,[NSThread currentThread]);
//        });
//    }
//     解析：向串行队列serial_queue里插入了100个block任务,系统会创建一个子线程，去依次执行这100个block任务。如果是通过dispatch_block_t创
//     建的blcok任务，未执行到的block可以被取消。

    
//    for (int i = 0; i < 100; i++) {
//        dispatch_queue_t serial_queue = dispatch_queue_create("threadAndQueue", DISPATCH_QUEUE_SERIAL);
//        dispatch_async(serial_queue, ^{
//            NSLog(@"%@",[NSThread currentThread] );
//            sleep(1);
//        });
//    }
//     解析：创建了100个串行队列，会开启100次子线程。
    
//    dispatch_queue_t serial_queue2 = dispatch_queue_create("threadAndQueue", DISPATCH_QUEUE_SERIAL);
//    dispatch_async(serial_queue2, ^{
//        for (NSInteger i = 0; i < 100; i++) {
 //           NSLog(@" i:%ld，currentThread:%@",(long)i,[NSThread currentThread]);
//        }
//    });
//     解析：向串行队列serial_queue里插入了1个block任务,系统会创建一个子线程，去执行这1个block任务。这个任务是依次打印i的值。
//
    
    

}



/*
 线程与内存
 */
- (void)threadAndMemory {
    
    NSMutableArray *mutableArray = [NSMutableArray array];
    dispatch_queue_t global_queue = dispatch_get_global_queue(0, 0);
    
    //1.
//    for (NSInteger i = 0; i < 100; i++) {
//        dispatch_async(global_queue, ^{
//            [mutableArray addObject:@(1)];
//        });
//    }

    
//    //2.
//    for (NSInteger i = 0; i < 1000; i++) {
//        dispatch_async(global_queue, ^{
//            self.name = [NSString stringWithFormat:@"name:%@", @"123"];
//        });
//    }
    
    
       //3.
//    for (NSInteger i = 0; i < 1000; i++) {
//        dispatch_async(global_queue, ^{
//            self.name = @"123";
//        });
//    }
    
    //上述几个方法线程安全吗？分别讲讲为什么
    //1.不安全，但不会crash，异步并发，系统会创建多个线程执行addObject方法，addObject方法未加锁,不是原子性操作，mutableArray的扩容无法受预期控制。
    //2.不安全,会crash，name是用nonatomic修饰的，其setter、getter方法都不是原子操作，因此可能出现_name指向的内存已经被回收了，但是其他线程同时使用_name release方法，导致crash
    //3.安全，不会crash，虽然name的setter、getter方法不是原子操作，但是因为_name指向的是字符串常量区，内存不会被释放，多次release也无妨，不会出现野指针crash问题。
    
}



//信号量
- (void)semaphore {
    
    //信号量控制最大并发数
    int taskCount = 100;
    dispatch_queue_t workConcurrentQueue = dispatch_queue_create("cccccccc", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t serialQueue = dispatch_queue_create("sssssssss",DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(3);
    dispatch_async(serialQueue, ^{
        for (NSInteger i = 0; i < taskCount; i++) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async(workConcurrentQueue, ^{
                NSLog(@"thread-info:%@开始执行任务%d",[NSThread currentThread],(int)i);
                sleep(1);
                NSLog(@"thread-info:%@结束执行任务%d",[NSThread currentThread],(int)i);
                dispatch_semaphore_signal(semaphore);
            });
        }
    });
    NSLog(@"主线程...!");
    
    
    //上述代码，将100个任务，以最大并发数3进行多线程执行。
    //dispatch_async(serialQueue，block）的目的是为了让主线程的打印先执行，子线程内部再开启一个for循环创建多线程。如果for循环放到主线程，随着
    //taskCount的增加，for循环的耗时变旧，则子线程有可能会先执行。一般的，两个线程谁先执行不能确定，但是如果for循环放在主线程，则随着循环次数变多，
    //主线程的代码执行可能会达不到你的预期
    
    
    
    
    //=============================
    
    
    //信号量进行多个线程同步
//    dispatch_queue_t queue = dispatch_queue_create("11111111", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
//    dispatch_async(queue, ^{
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        for (int i = 0; i<100; i++) {
//            NSLog(@"111");
//        }
//        dispatch_semaphore_signal(semaphore);
//    });
//
//    dispatch_async(queue, ^{
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        for (int i = 0; i<100; i++) {
//            NSLog(@"222");
//        }
//        dispatch_semaphore_signal(semaphore);
//    });
//
//    dispatch_async(queue, ^{
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        for (int i = 0; i<100; i++) {
//            NSLog(@"333");
//        }
//        dispatch_semaphore_signal(semaphore);
//    });
//
//    NSLog(@"主线程...!");
}


//死锁
- (void)deadLock {
    
    
//    dispatch_queue_t queue = dispatch_queue_create("serial", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_async(queue, ^{
//        NSLog(@"1:%@",[NSThread currentThread]);
//        dispatch_sync(queue, ^{
//            NSLog(@"2:%@",[NSThread currentThread]);
//        });
//        NSLog(@"3");
//    });
    
    
    
//    NSLog(@"1");
//
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        NSLog(@"2");
//    });
//
//    NSLog(@"3");
    
    
//
//    dispatch_queue_t queue = dispatch_queue_create("serial", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_async(queue, ^{
//        NSLog(@"1:%@",[NSThread currentThread]);
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            NSLog(@"2:%@",[NSThread currentThread]);
//            sleep(3);
//        });
//        NSLog(@"3:%@",[NSThread currentThread]);
//    });
    
}


//深浅拷贝
- (void)shallowAndDeepCopy {
    

//    NSMutableArray *sources = [NSMutableArray arrayWithArray:@[@"lcc"]];
//    NSLog(@"%@",sources);
//
//
//    self.array = sources;
//
//    NSLog(@"%@",self.array);
//
//    [sources removeAllObjects];
//
//    NSLog(@"%@",self.array);
    
    
//    NSString *sources = @"lcc";
//    NSString *a2 = [sources mutableCopy];
//    
//    NSArray *sourcesA =@[@"lcc"];
//    NSString *A2 = [sourcesA mutableCopy];
//    
//    NSLog(@"11");
    
}



//自动释放池
- (void)aotureleasepool {
    
    //案例1
//    int main(int argc, char * argv[]) {
//        NSString * appDelegateClassName;
//        @autoreleasepool {
//            // Setup code that might create autoreleased objects goes here.
//            appDelegateClassName = NSStringFromClass([AppDelegate class]);
//        }
//        return UIApplicationMain(argc, argv, nil, appDelegateClassName);
//    }
    
    //上述代码什么意思？
    
    //案例2
//    Person * p = [[Person alloc] init];
//
//
//    while (1) {
//
//    }
    //q1：ARC下，上述代码，p会释放吗？
    //答:不会，因为函数不会退出，p对象无法release
    //q2:如何让p释放？
    //答:添加到自动释放池
    
    
    
    //q3:现在for循环产生大量的临时变量，内存是否会激增，会的话要怎么解决?
    //答:不一定，新版本的Xcode，arc做了优化，一个函数内的for循环或者while循环产生大量的临时变量，不一定会在函数退出时插入release，而是在每次循环结束的时候就插入了，但是老版本的arc，所有的临时变量会在函数退出时才自动release，导致积累大量的临时变量。为了解决内存上升，可以每次循环时，都把临时变量加入到@autoreleasepool中，提前释放。
}




- (void)timer {
    
    
    /*
     - (void)viewDidLoad {
         [super viewDidLoad];
         // Do any additional setup after loading the view.
         
         NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2
                                                           target:self
                                                         selector:@selector(timeAction)
                                                         userInfo:nil
                                                          repeats:YES];
         
     }

     - (void)timeAction {
         NSLog(@"timeAction");
     }

     - (void)dealloc {
         NSLog(@"dealloc");
     }
     
     
     
     q1:上述代码有什么问题？
     答:viewcontroller不会释放。因为定时器没有释放，而定时器强持有了self。
     
     q2: __weak typeof(self) weakSelf = self,target传weakSelef呢？
     答:不可以，在解决block循环引用时，可以通过__weak修饰，为的是让让block持有self时以weak的方式不增加引用计数，但是这里timer的target是strong类型的，weakSelf和self地址相同，传入weakSelf，依然会让引用计数加1。
     
     q3:解决Timer的内存泄漏的方案：
     1.杜绝timer和target的循环引用，同时确保执行timer的invalidate方法。
     2.如果在target的dealloc方法里调用invalidate方法，需要想办法让timer弱引用target，可以用blcok+__weak,也可以使用NSProcy或者中间类来实现。
     3.target使用类对象或者单例对象。
     
     */
    
}


- (IBAction)click:(UIButton *)sender {

}

@end
