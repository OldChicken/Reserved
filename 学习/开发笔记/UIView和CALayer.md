#### UIView和CALayer

* UIView可以响应事件，Layer不可以.
* UIKit使用UIResponder作为响应对象，来响应系统传递过来的事件并进行处理。在 UIResponder中定义了处理各种事件和事件传递的接口。
* UIApplication、UIViewController、UIView、和所有从UIView派生出来的UIKit类（包括 UIWindow）都直接或间接地继承自UIResponder类。
* CALayer直接继承 NSObject，并没有相应的处理事件的接口。
* UIView是CALayer的delegate
* UIView主要处理事件，CALayer负责绘制
* 每个 UIView 内部都有一个 CALayer 在背后提供内容的绘制和显示，并且 UIView 的尺寸样式都由内部的 Layer 所提供。两者都有树状层级结构，layer 内部有 SubLayers，View 内部有 SubViews.但是 Layer 比 View 多了个AnchorPoint
