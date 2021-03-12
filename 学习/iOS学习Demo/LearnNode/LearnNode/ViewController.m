//
//  ViewController.m
//  LearnNode
//
//  Created by Lechech on 2021/3/12.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic,copy) NSString *name;
@property (nonatomic,assign) BOOL isMainThreadExit;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //1.消费者生产模式
    [self produceDemo];
    
    
    //===============================
    
    
    
    //2.线程与队列
//    [self threadAndQueue];
    
    
    
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
    //问：以下两for循环有什么区别？
    
    
    for (NSInteger i = 0; i < 10000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            self.name = [NSString  stringWithFormat:@"name:%ld", i];
//            NSLog(@"currentThread:%@\n",[NSThread currentThread]);
        });
    }
//    解析：该for循环创建了10000次子线程(不是同时创建了10000个，gcd会自动控制最大并发数)，对name属性进行set操作。如果name属性是非原子性（nonatomic）的，程序极容易崩溃。因为多个线程同时setter，但是setter没加锁，所以容易重复release，导致野指针。改成atomic，读写方法就是线程安全的。
//    奇怪的是，如果在self.name后面加上一行打印代码，也不会崩溃。原因未知。加上其他代码没效果。


    
    dispatch_queue_t queue = dispatch_queue_create("threadAndQueue", DISPATCH_QUEUE_SERIAL);
    for (NSInteger i = 0; i < 10000; i++) {
        dispatch_async(queue, ^{
            self.name = [NSString  stringWithFormat:@"name:%ld", i];
            NSLog(@"currentThread:%@\n",[NSThread currentThread]);
        });
    }
//    该for循环创建了一个线程，并往其串行队列中插入了10000个任务，每个任务都是修改name的属性。

    
    
    
    
    dispatch_queue_t queue2 = dispatch_queue_create("threadAndQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue2, ^{
        for (NSInteger i = 0; i < 10000; i++) {
            self.name = [NSString  stringWithFormat:@"name:%ld", i];
            NSLog(@"currentThread:%@\n",[NSThread currentThread]);
        }
    });
//    该for循环创建了一个子线程，并往这个线程队列中插入了一个任务，这个任务是修改name属性10000次。
    
    
    
    

    


}


@end
