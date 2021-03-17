#### 简述NSRunLoop

NSRunLoop是苹果封装的一个消息循环类。每一个NSRunLoop实例对象，可以简单的看作一个While循环。退出该循环的条件是收到某条指令消息，否则程序将一直保持运行。当app运行后，主线程就处于一个NSRunLoop之中，因此主线程可以持续的接收用户事件，而杀死app则可以视为退出While循环的指令。当然，实际情况要复杂得多，但明确的是，RunLoop是为线程服务，与线程密不可分，一一对应。对于RunLoop，需要明确以下几点：
* **主线程的RunLoop默认启动。程序运行后，在入口main函数中，会为主线程设置一个NSRunLoop对象。**
* **对其它线程来说，RunLoop默认不启动，如果子线程需要一直处于循环监听状态则可以手动配置和启动，如果子线程仅仅执行一个长时间的异步任务则不需要。**
* **RunLoop需要处理多种消息源，因此有多种模式用于处理各种消息。常用的有kCFRunLoopDefaultMode、UITrackingRunLoopMode、UIInitializationRunLoopMode:、NSRunLoopCommonModes**


**延伸问题**:
为什么定时器需要加入到RunLoop之中？
NSRunLoop几种模式的区别？有哪些使用场景？
NSRunLoop的生命周期？

 ---
