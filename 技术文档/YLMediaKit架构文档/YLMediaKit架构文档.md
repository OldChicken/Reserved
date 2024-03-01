 # YLMediaKit架构文档
 
背景
多媒体处理是大部分App都避不开的功能，刚加入YallaChat时，研发侧有一个需求是提高上传图像与视频的压缩率，并且尽可能的保证清晰度，同时产品侧有图像编辑相关的需求。当时在接入三方SDK和自研两个方向的选择上，考虑到M软件的编辑功能不会像专业编辑软件那样复杂，但YallaChat又要比国内的一般社交软件丰富，所以最终慢慢衍生出了MediaKit这个组件。
架构
 YallaChat > YLMediaKit架构文档 > MediaKit架构图.png
整个MediaKit组件对外提供了三个核心能力，即多媒体的选取(Picker)、编辑(Editor)、压缩(Compressor)。Common中提供了三个模块通用的一些工具类、基类以及扩展类。比如资源浏览器、视频播放器、自定义转场动画等。

调用流程
YallaChat > YLMediaKit架构文档 > image-2023-12-19_14-3-47.png
MediaKit最终的目的是输出YLMediaKitOutputItem对象(下图)数组。因为输出需要满足多场景的不同要求，所以Picker、Editor、Compressor都需要支持配置化。
YLMediaKitOutputItem  
YallaChat > YLMediaKit架构文档 > 截屏2023-12-11 11.43.49.png

从上述流程图中可以发现Composition这个对象贯穿了所有模块。这里重点讲一下这个数据模型。

YLMediaEditComposition : 合成模型，是整个组件模块间传递的对象。它作为编辑器(Editor)和压缩器(Compressor)的入参，具有两个关键属性asset和context(其他属性已忽略)。
YallaChat > YLMediaKit架构文档 > image-2023-12-19_14-19-20.png

YLMediaAsset  资产协议，在日常开发中，客户端的媒体资产的来源大致分为三类，沙盒资产(URLPath)、相册资产(PHAsset)、内存资产(UIImage、GifData)。MediaKit中定义了YLMediaSandboxAsset(沙盒资产模型)、YLMediaAlbumAsset(相册资产模型)、YLMediaMemoryPhotoAsset(内存图片资产模型)来处理三种来源，并遵守了YLMediaAsset协议。
YallaChat > YLMediaKit架构文档 > image-2023-12-19_14-15-39.png

YLMediaEditAsset 资产类簇，用于初始化上述三种模型，通过类簇将YLMediaSandboxAsset、YLMediaAlbumAsset、YLMediaMemoryPhotoAsset组合抽象的YLMediaAsset协议之下。
YallaChat > YLMediaKit架构文档 > 截屏2023-12-11 11.20.45.png

YLMediaContext  编辑上下文协议，编辑的目标对象目前有图片、Gif、视频三类，对应的上下文模型为YLMediaEditPhotoContext、YLMediaEditVideoContext、YLMediaEditGifContext，为了抽象这三个对象，MediaKit定义了上下文协议YLMediaContext，只有实现该协议的对象才可以被编辑器(Editor)编辑，或者被压缩器(Compressor)压缩。
图略(参数较多，细节不作展开)

YLMediaEditContext  编辑上下文类簇，用于初始化上述三个不同的上下文模型，通过类簇将YLMediaEditPhotoContext、YLMediaEditVideoContext、YLMediaEditGifContext组合在抽象的YLMediaContext协议之下。
YallaChat > YLMediaKit架构文档 > image-2023-12-19_14-14-4.png

整个MediaKit的核心数据结构如上，整个模块内部调用流程，总结下来就是：
基于各模块的Config和用户交互，将内存图片、沙盒视频、沙盒图片、相册视频、相册图片五种不同场景的输入，通过YLMediaAsset和YLMediaContext两个协议抽象成
YLMediaEditComposition对象。其中原始信息存放在不可变对象asset中，编辑信息存放在可变对象context中，用户通过UI交互动态的修改context，最终将YLMediaEditComposition对象转换成YLMediaKitOutputItem对象的一个过程。

Picker(选择器)技术点
选择器作为Editor或者Compressor的输入前置，输出的对象有两种，Album输出的是PHAsset(系统的图片资产或者视频资产)，Camera输出UIImage或PhotoURL或VideoURL，统一通过YLMediaEditAsset类簇初始化后，生成YLMediaEditComposition对象传入Editor或Compressor。

1.Album开发遇到的坑
相册模块是对系统相册资产(PHAsset)的选取、预览操作。网上也有很多现成的参考。这里仅说一下开发过程中遇到一些坑：
iCloud资产判断：经过调研，Apple没有提供准确的判断资产是否在本地的Api，网上搜到的本地查询的相关方法都不准。最终解决方案是通过给PHImageManager添加异步查询方法fetchLocalAvailable来判断。其中图片是设置获取原图+不不支持网络下载，如果能够获取到则认为本地存在，反之不存在。视频是设置获取高质量视频AVAsset+不支持网络下载，如果能获取到AVAsset则说明本地存在，反之不存在。
PHCachingImageManager，官方下载的相册Demo中使用该类来进行PHAsset资源的读取，在调研后发现这个读取器会引起MMO，坑比较多。所以最终还是改回了PHImageManager，但是因为图像没有做缓存，每次PHAsset的读取又是异步的，导致快速滑动的时候，性能较差的手机会看到图片从模糊变清晰的刷新过程。加上现在是否iCloud资产也是异步判断的，所以快速滑动时CPU的负载会比较高(30%~70%左右)。

2.Camera开发技术难点
iOS客户端相机功能的开发思路都是围绕系统的AVCaptureSession类实现相机相关的功能接口，使用AVCaptureInput和AVCaptureOutput来进行输入、输出的相关设置，UI部分则比较简单，网上能找很多开源Demo。
MediaKit中的Camera是将相机的逻辑功能封装在了CameraEngine中，UI封装在了CameraController中。CameraEngine用于控制硬件输入以及图像/适配/音频输出，并封装好拍照、拍摄、变焦、反转摄像头等相关AP供业务层调用。
CameraEngine实际上是对系统的以下对象进行的封装。
YallaChat > YLMediaKit架构文档 > image-2023-12-19_14-53-39.png

不同于网上搜到的开源Demo，CameraEngine中使用AVCaptureVideoDataOutput+AVCaptureAudioDataOutput代替AVCaptureMovieFileOutput来进行视频的输出。并引入了帧编辑的概念，用于编辑以及写入相机输出的每一帧图像/音频，以达到需求中要求的不同旋转、镜像、裁剪要求。这里讲一下背景和原理。

理解相机物理缓冲区坐标系统
iOS的相机硬件采集的图像有一个输出缓冲区AVCaptureConnection的概念。
相机拍照和录制视频有各自的缓冲区，分别为PhotoConnect和VideoConnect，它们可以通过AVCaptureOutput的下述API获取。
YallaChat > YLMediaKit架构文档 > image-2023-12-21_10-21-28.png

缓冲区有自己的参考坐标系，我们在不修改缓冲区坐标系的前提下，观察拍摄时的手机方向不同，从缓冲区拿到的图片结果:
YallaChat > YLMediaKit架构文档 > 手机朝上拍.pic.jpg  YallaChat > YLMediaKit架构文档 > 手机朝上拍结果.png
         手机朝上拿着拍摄(刘海朝上)                                                              拍摄结果           


YallaChat > YLMediaKit架构文档 > 手机朝左拍.pic.jpg    YallaChat > YLMediaKit架构文档 > 手机朝左拍结果.png
       手机朝左拿着拍摄(刘海朝左)                                                             拍摄结果           



YallaChat > YLMediaKit架构文档 > 手机朝右拍.pic.jpg  YallaChat > YLMediaKit架构文档 > image-2023-12-13_10-33-27.png
         手机朝右拿着拍摄(刘海朝右)                                                            拍摄结果           



YallaChat > YLMediaKit架构文档 > 手机朝下拿着拍摄.jpg   YallaChat > YLMediaKit架构文档 > image-2023-12-13_10-44-23.png
        手机朝下拿着拍摄(刘海朝下)                                                               拍摄结果           


对比上述左右两列图片，我们可以很明显的发现，除了手机朝左拿着拍的时候，结果图像是我们期望的方向，其他拍摄结构的方向都不符合期望。为什么会出现这个问题？
因为在相机输出缓冲区的坐标世界中，手机刘海屏永远是它的左边。
我们身处现实世界坐标系观察，就会出现上述拍摄方向和结果照片方向不同的情况。
事实上，我们可以盯着左边的一组照片，旋转我们自己视角或者手机，旋转的参考方向是，永远将手机刘海屏作为我们的左边，这样就能以相机视角得到右边的拍摄结果。

如何从缓冲区得到我们希望的正确方向的图片？
相机既然有自己的坐标系，因此想要获取现实坐标系视角下的图片，有两个方案:
方案一：根据设备方向旋转相机缓冲区的方向。（网上大部分相机Demo的实现方案）
方案二:   根据设备方向旋转输出图像的方向。      (矫正右边一排图片的方向)

方法一系统已经提供了相关的API，我刚接手的时候YallaChat的相机也是这么实现的，但是遇到了许多无法实现的需求以及难以解决的Bug。为此我查询了官方文档，理解了缓冲区的实现原理：
PhotoConnect: 调整PhotoConnect的方向，系统并不会旋转缓冲区，而是给缓冲区的图片加一个Orientation标记。图片像素的实际排列方向依然不变，只是通过这个方向标记，在图片像素渲染到ImageView上的时候，对UIImage做仿射旋转变换，以达到正确的视觉效果。
(这样的好处是性能非常快，缓冲区的图像从头到尾都不需要重绘，但如果对缓冲区图像输出进行重绘，这个方向标记会被重置为.up，我们需要保证重绘后方向标记得和绘制前一致。这也是大部分iOS开发遇到过的两个Bug，为什么iOS的图片在OS平台展示正确，上传给其他平台，方向就错了。为什么原本在OS平台展示正确的UIImage，重绘之后方向也不正确了)
VideoConnect: 调整VideoConnect的方向，系统会旋转缓冲区，缓冲区的图像实际上都会被重绘，因此每一次改变VideoConnect的方向，都会有一定的性能损耗。

理解了两个缓冲区的原理，通过方案一来控制输出图像的方向的问题不言而喻：
拍照的图片为了能够保证多平台展示正确，设置PhotoConnect缓冲区方向并没有太大意义，从缓冲区取出来的图片我们还是要对方向重新修正重绘。（参考MediaKit中UIImage的fixOrientationImage方法)
视频拍摄虽然能通过旋转缓冲区改变方向，但每次运行时修改都有性能损耗，实际拍摄过程中，手机方向是可能频繁改变的，如果不动态调整缓冲区方向，拍摄出来的视频有问题，但一旦动态调整缓冲区方向，又会造成卡顿和丢帧的问题。
视频拍摄过程中，前后摄像头也是可以动态切换的，每次切换摄像头，摄像头输入需要切换，输出缓冲区也需要重新设置方向以及是否镜像，同样也会造成卡顿和丢帧。(很多App在拍摄过程中不支持切换摄像头)
图片和视频的缓冲区方向需要单独设置，代码分散，不易维护管理。
缓冲区只支持设置镜像和旋转，并不支持裁剪，有时候我们还需要对输出的图像进行裁剪操作。

为了能彻底根绝这些问题，CameraEngine最终实现了方案二。即VideoConnect和PhotoConnect的方向都不做修改，让其始终保持其原有的方向，而是对从缓冲区拿出来的每一帧进行动态编辑。比如根据当前是否前后摄像头进行镜像处理，当前的手机方向进行旋转处理，当前的拍摄比例进行裁剪处理。所有的编辑入口都汇聚在同一处。
把两种采集前的缓冲区旋转、镜像设置，统一改成了缓冲区输出图片的编辑，这使得整个相机模块对图像的控制程度更加灵活，并且具备了更强大的扩展能力。比如将来如果需要做美颜相机，则不需要再关心缓冲区的所有逻辑，只需要对已有的编辑功能代码进行扩展即可。
对缓冲区输出图像的旋转、镜像、裁剪相关的代码都集成在CameraEngine的Adapt扩展中。后续可以封装成Adapter类来专门处理编辑相关的功能。

解决方案二引发的黑帧(Black Frame)问题:
为了能够拿到视频的每一帧，我们需要使用AVCaptureVideoDataOutput+AVCaptureAudioDataOutput代替AVCaptureMovieFileOutput。AVCaptureMovieFileOutput使用相对简单(网上搜到的大部分Demo都是基于这个Output)，只需要给其设置好路径和码率，设定好缓冲区方向，AVCaptureDeviceInput和AVCaptureDeviceInput采集到的图像帧和音频帧都会按照配置写入到指定路径。
改用DataOutput后则稍微麻烦一些，我们需要通过设置其代理拿到SampleBuffer，对SampleBuffer完成帧编辑后，还需要用到AVAssetWriter来进行音频流和视频流的实时写入，当时测试发现了黑帧的问题，即iOS录制的视频，在iOS端播放时经常会出现第一帧或最后一帧是黑帧，在安卓端则显示正常。早期使用AVCaptureMovieFileOutput时则没有此问题。经过排查，根本原因是音频流和实时流的硬件采集的开始/结束并没有一个固定的先后顺序，导致可能会出现音频第一帧的pts比视频第一帧的pts小，或者音频最后一帧的pts比视频最后一帧的pts大，而iOS的播放器在播放某一帧画面时，如果该帧只有声音而没有画面，就会展示黑帧。安卓播放器则是展示上一个缓存帧。
为了解决黑帧问题，Engine中使用如下三个字段，来保证音频第一帧的pts大于视频第一帧pts，音频最后一帧的pts一定小于视频最后一帧的pts，这样能确保最终播放器上的每一帧，不会出现只有声音没有画面的情况。
YallaChat > YLMediaKit架构文档 > image-2023-12-19_15-52-42.png

Editor(编辑器)技术点

1.iOS端常用的多媒体处理框架简介
AVFoundation： Apple原生的用于媒体资源的采集、播放、合成、编解码、读写的框架，涵盖了媒体资源处理相关的几乎所有上层接口。
FFmpeg：三方开源的基于C语言的跨平台的多媒体处理框架，提供了涵盖音视频播放、合成、编解码、读写相关的功能。
CoreImage： Apple原生的基于Metal的图像帧处理框架。内置了许多滤镜（CIFilter）。
GPUImage    基于OpenGL的图像处理框架（3.0后也支持了Metal），使用链式编程对输入图像进行各种滤镜操作，提供了非常丰富的滤镜（filter）。也支持自己编写着色器（shader）实现各种效果。

框架    功能    编码方式    优点    缺点
AVFoundation    
多媒体采集
多媒体播放
多媒体合成
多媒体编解码
多媒体读写
...
硬编码    
集成与调用方便，无上手门槛，对iOS开发者较友好
不会引入额外包体积
使用GPU进行硬编码，效率较高

无法修改源码，无法实现某些定制化需求
无法跨平台使用
ffmepg    
多媒体播放
多媒体合成
多媒体编解码
多媒体读写
支持多种格式转换
...
软编码    
跨平台
开源，支持修改源码
可配置化，可以只集成自己需要的功能，比如音频模块，视频模块。
支持命令行
集成麻烦，容易和其他三房库产生冲突
需要进行桥接封装
CPU负担较高

框架    优点    缺点
CoreImage    
官方框架，使用放心，维护方便。
支持CPU渲染，可以在后台继续处理和保存图片。
一些滤镜的性能更强劲。例如由Metal Performance Shaders 支持的模糊滤镜等
支持使用Metal 渲染图像。而Metal在iOS 平台上有更好的表现。
与Metal, SpriteKit, SceneKit, Core Animation 等更完美的配合。
定制化程度低，扩展性不强
大图处理上会有质量损失
GPUImage    
开源
丰富的输入组件，摄像头、图片、视频、OpenGL纹理、二进制数据、UIElement（UIView， CALayer）
大量现成的内置滤镜
颜色类（亮度、色度、饱和度、对比度、曲线、白平衡 ...）
图像类（放射变换、裁剪、高斯模糊、毛玻璃效果 ...）
颜色混合类（差异混合、alpha混合、遮罩混合 ...）
效果类（像素化、素描效果、压花效果、球形玻璃效果 ...）
丰富的输入输出
链式调用
定制化程度高
支持自定义着色器
支持自定义滤镜
Swift版本不太稳定
3.0版本才支持Metal

MediaKit中的编辑模块选用的技术是AVFoundation+CoreImage。事实上，不论是FFmepg还是GPUImage，硬件层面API的调用都需要通过AVFoundation，所以AVFoundation是iOS多媒体编辑必不可缺的框架。

2.理解一些图像编辑涉及到的常用语言及数据结构
UIImage：UIKit中的图像对象，是对CGImage和CIImage的上层封装。
CGImage：CoreGraphics下的图像对象，存放了图片的Bitmap信息，用于解码与渲染。
CIImage：CoreImage下的图像对象，保存了生成最终图像所需要的编辑信息，用于图像编辑。
简单理解，UIImage代表着一道菜的抽象，CGImage代表着真正的食材，CIImage则代表着食谱。
当我们初始化一个UIImage时，CGImage不为nil，但它并不会立刻被解码，CGImage使用了懒解码策略，只有在被渲染到view上时才会调用解码器进行解码，因此大图片渲染会卡顿，很多三方库会把解码放到子线程。
当我们初始化一个UIImage时，CIImage默认为nil，我们可以通过CIImage来编辑这张图并绘制出我们想要的新图像。

CVPixelBuffer：视频流中的帧对象，包含解码后的图像帧。
CMSampleBuffer：视频中的媒体流对象，包含一个或者多个解码或非解码的数据样本。(CameraEngine中从缓冲区获取到的对象就是该模型)
视频帧处理中的对象，可以和Image模型互相转化，CVPixelBuffer也可以直接渲染或者进行IO读写。是视频编辑中的两个基本对象。

AVAsset: AVFoundation最核心的数据结构，是音、视频媒体的抽象资产类。通过这个数据结构，无论我们处理M4V视频或MP3音频，对你和框架而言，面对的只有资源这个概念，不需要考虑多种编解码器和容器格式不同带来的困扰。
AVCompostiom: 音、视频媒体合成资产类，是多媒体轨道的集合，继承于AVAsset。当我们需要对视频进行编辑时，则需要通过其子类AVMutableCompostiom来进行资源的初始化。
AVVideoComposition：视频轨道合成控制类。用于确定视频合成模型的轨道合成方式。从命名看起来 AVVideoComposition 好像跟 AVComposition 有什么血缘关系，但两者没有任何继承关系。
AVAudioMix: 音频轨道合成控制类，用于确定音频合成模型的轨道合成方式。
视频处理所涉及的上层核心数据结构，实际上AVCompostiom相当于多个原始多媒体，AVVideoComposition和AVAudioMix则表示如何合成这些多媒体。她们之间的关系等同于MediaKit中的asset和context的关系。

Opengl：跨平台的开放图形库，这个库的作用，简单理解就是将运行内存中的图像数据处理成GPU能理解的数据结构后，将其输送到GPU的显存缓冲区。算是作为GPU和CPU之间的一个乔接，具有直接调用GPU硬件API的能力。
Context：上下文，Opengl中存储状态机的数据结构
Verter：顶点，Opengl中的数据结构
Texture：纹理，Opengl中的数据结构
Sharder：着色器，运行在GPU上的代码程序，用于像素和定点坐标处理。在GPU开始执行OpenGl的渲染任务时，我们依然可以通过着色器编程去改变图像的输出结果。
GLSL：编写Sharder着色器的语言，代码风格和c几乎一样。
…
OpenGL只有350个接口，但是因其跨平台的特性，所以游戏、CAD、AR、VR领域中都有所涉及。内部实现了数学中将三维世界映射到二维屏幕的MVP坐标转换矩阵，可以看作是学习计算机图形学的入门语言。Metal和OpenGl的关系，类似于Swift和OC的关系。但是Metal只适用于OS平台。

2.GPU渲染流程


后续如果编辑器需要开发一些复杂的功能，比如像素级别的转场效果、抠图、扣像等，那么Opengl与GLSL着色器层面都需要进行相关学习。

Compressor(压缩器)技术点
iOS视频压缩策略
图片压缩： UIKit + ImageIO
传统视频压缩：AVAssetExportSession，可配置化程度较低，效果不理想。
自定义视频压缩: AVAssetReader+AVAssetWriter进行压缩，可配置化程度较高。

待优化问题
涉及到UI和用户交互较多的组件，很难真正组件化。加上我们公司的app都需要支持多语言和暗黑，以及有大量埋点的需求，所以翻译、icon、theme、point在不同项目中都不一样。真正能够多项目复用的，只有非UI部分的代码与算法以及一些工具类。
代码规范有所欠缺。部分代码不够美观。
各模块的配置虽然有一定注释，但是缺少详细的示例代码，三个模块的配置项加起来有三四十个，略显复杂。并且目前的配置组合都是基于业务场景，没有覆盖所有情况。
缺少完善的错误处理机制。IO、压缩、编辑实际上都存在发生异常错误的可能，目前MediaKit都是比较简单暴力的处理了这些异常，比如直接中断流程，更好的做法应该是向调用层抛出异常进行处理，以提高用户体验。



 
