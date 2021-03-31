#### 简述NSRunLoop



* **runloop是为了让线程保活，与线程一一对应。
* **主线程的RunLoop默认启动。程序运行后，在入口main函数中，会为主线程设置一个NSRunLoop对象。**
* **对其它线程来说，RunLoop默认不启动，如果子线程需要一直处于循环监听状态则可以手动配置和启动，如果子线程仅仅执行一个长时间的异步任务则不需要。**
* **RunLoop需要处理多种消息源，因此有多种模式用于处理各种消息。常用的有kCFRunLoopDefaultMode、UITrackingRunLoopMode、UIInitializationRunLoopMode:、NSRunLoopCommonModes**
* **RunLoop同时只能在一种模式下运行，所以定时器创建后，需要加入到UITrackingRunLoopMode和kCFRunLoopDefaultMode中，才能在scrollerView滑动、停止滑动时，定时事件都能被响应。


