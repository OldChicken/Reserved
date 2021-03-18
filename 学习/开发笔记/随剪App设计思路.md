# 随剪App 架构模式、合成、渲染流程




随剪介绍:
一款纯粹的视频编辑软件，支持主流的功能，包括视频转场动画、滤镜、裁剪、倍速、导出、扣色、贴纸等主流功能，同时加入了公司自研的人脸跟踪、表面跟踪功能。
体验感以及专业性应该超越了市面上不少的软件。非常纯粹干净。

历程：旧项目，MVC，UI更新不灵活、代码繁琐，最大的问题在于数据模型设计的非常不好，一个项目分成好多json和资源文件，可能由多个路径下的文件拼凑而成，扩展性很差，难以维护迭代。举例：前进后退功能。
     新项目：MVVM+RAC，UI更新非常灵活，一个项目是一个比较庞大的json，json里存放了项目的必要信息+一个历史栈数组，数组的每一个元素就是一个snapshoat(依然是一个json模型)，可以理解成一个快照。即，任何一步编辑操作，都会新生成一个snapshoat，添加进数组历史栈中，作为新的一步。

你可以理解成，某一时刻改动了项目，则整个界面发生了改变以后，将这个界面投射成一个新的snapshoat，下次再读到这个snapshoat时，根据这个snapshoat还原出界面，简单说就是View的改动，导致模型拷贝一份snapshoat，在新的snapshoat上更新改动，存入数组。

snapshoat:记录了当前一步渲染状态的所有信息，用一个snapshoat，就能还原出一个完整的画面，当前编辑页面有多少个图层，每个图层有多少个素材，素材旋转了多少度，透明度是多少等等等等一系列信息，全部都保存在snapshot中。因此，通过snapshoat还原出UI并渲染，以及UI的每一步需要记录的操作新生成snapshot，是整个架构里的难点。对snapshoat的模型设计要求非常高。

渲染:渲染的核心思路，我称之为重定向，利用的是AVPlayer播放过程中对其输出进行拦截，需要注意的是，不能直接拦截buffer，因为得到的信息不够，我们拦截过程中，除了要获取到当前帧的位图，还需要获取到时间信息、轨道信息等。因此我们利用AVMutableVideoComposition类来进行拦截,首先需要构造一个视频合成类，视频合成类需要做的，是根据输入的一个或者多个cvpixelBuffer(贴纸、视频帧、图片都有可能)，根据功能，videoComposition.customVideoCompositorClass = [CustomClass class]在CustomClass需要遵守AVVideoCompositing协议，实现renderContextChanged和startVideoCompositionRequest两个方法，既可以在这个方法中，拦截AVplayer

核心设计模式：快照模式 + 策略模式

核心思路：通过
