# 音频、视频倒放算法OC实现


思路:在iOS中，可以利用CMSampleBufferRef、AVAssetWriter、AVAssetWriterInput、AVAssetReader、AVAssetReaderOutput实现音视频。需要注意的是，iOS没有提供现成的逆序读取Api，因此视频、音频的逆序读取需要自己实现。核心思路：找到视频或者音频的最小单元，逆序读出来，同时修改每一帧的PTS、DTS时间信息(AVAsset基本没有B帧，所以DTS可以不需要)。需要注意的是：视频的最小单元是画面帧，音频的最小单元是采样点。通过AVAssetReader和AVAssetReaderOutput解码出来的CMSampleBufferRef数组，每一个buffer可以视为视频的最小单元帧，而对于音频，最小单元不是CMSampleBufferRef，而需要将每一个CMSampleBufferRef再转换成AudioBufferList数组，数组内含有多个解码后的音频字节流(一般情况就一个)，先将数组元素本身逆序，同时对于每一个字节流元素，根据通道数、采样频率、采样深度，计算出这段字节流共有含有多少个采样样本，通过最小样本单元，将这段字节流再逆序一遍。

遇到的问题1:音频倒放的最小单元需要注意，之所以刚开始，我们的音频倒放后效果很差，甚至二次倒放后都对不上，就是因为最小单元找错了。要想比较合理的倒放音频，就要从音频本身的数模转换来看。一段模拟信号如何转换成数字信号？实际上是根据采样率和采样深度，在连续的模拟信号中，通过一定频率，在某个点采集数据。采样深度越高，频率越快，声音自然越真实。那么一段声音的数字信号的倒放，自然是把这些采样点逆序。此外：CMSampleBufferRef里有个numberSamples，最开始我把这个当成了采样点的个数，实际上不对，样本个数和采样个数还是不一样，一个样本可能包含两个声道的采样。所以numberSamples * 2，才是采样次数，每次用32bit，四个字节。


遇到的问题2:音视频倒放，需要将解码后的数据暂时写到内存中中的，音频还好，但是如果把一个视频一下子全部解码出来，内存很容易爆掉。因此音视频编解码需要考虑内存使用。这里有会一个窗口的概念，AVAssetReaderOutput在读取AVAsset时，必须是从前往后读，但是读取的时间范围可以自己定义。因此我们可以把一整段的读取，分成几个小的窗口来读，每个窗口就是一个CMTime的duration，比如一次读取2秒。8.5秒的音频就可以分成5次来读，你可以自己定义每个窗口的大小，在我的实现中，视频解码窗口，我是按照float sec = self.maxVideoWindowSizeInBytes/(w*h*4)/track.nominalFrameRate来计算最小窗口的时间长度，其中self.maxVideoWindowSizeInBytes的大小是200M，也就是限定了一次行最多只能读取200M的大小。音频窗口，我默认一次读取100秒的音频，没有做特殊计算处理。


遇到的问题3:整个算法在业务层是基于一个简单的消费者生产模式实现的，AVAssetReader设置好读取的timeRange，再根据窗口大小，从后开始一段一段读取数据，每次读完存放到一个数组缓冲区(当然这个数组里的还是顺序的)，当缓冲区内有数据时，丛该数据缓冲区，逆序读取最后一个buffer，通过AVAssetReaderInput的appendSampleBuffer写入到指定文件中。


音频倒叙算法如下：
- (BOOL)reverseAudioSamplesOfSampleBuffer:(CMSampleBufferRef)sampleBuffer error:(NSError *__autoreleasing *)error{
    
    //need to introspect into the opaque CMBlockBuffer structure to find its raw sample buffers.
    CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    AudioBufferList audioBufferList;
    OSStatus status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                            NULL,
                                                            &audioBufferList,
                                                            sizeof(audioBufferList),
                                                            NULL,
                                                            NULL,
                                                            kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                            &buffer
                                                            );
    if (status != 0) {
        *error = [NSError errorWithDomain:[NSString stringWithFormat:@"Failed reading audio buffer list from sample buffer. OSStatus: %d, asset: %@",status,self.assetReader.asset] code:0 userInfo:nil];
        return NO;
    }else{
    
        //mBuffers数组 逆序
        for (int bufferCount=0; bufferCount < audioBufferList.mNumberBuffers >> 1; bufferCount++) {
            SInt16 *samples = (SInt16 *)audioBufferList.mBuffers[bufferCount].mData;
            SInt16 *samples1 = (SInt16 *)audioBufferList.mBuffers[audioBufferList.mNumberBuffers - 1 - bufferCount].mData;
            audioBufferList.mBuffers[bufferCount].mData = samples1;
            audioBufferList.mBuffers[audioBufferList.mNumberBuffers - 1 - bufferCount].mData = samples;
        }
        
        //mData元素 把采样点逆序存储
        if (audioBufferList.mNumberBuffers > 0) {
            for (int i = 0; i<audioBufferList.mNumberBuffers; i++) {
                int dataByteSize = audioBufferList.mBuffers[i].mDataByteSize;
                //样本个数 = 总长度 / 8 (一个样本有两个采样点，因为是双声道)
                int numSamples = dataByteSize >> 3;
                if (numSamples) {
                    uint *mData = (uint *)audioBufferList.mBuffers[i].mData;
                    //总的采样点 = 总长度 / 4 （一个采样点需要4个字节存储，刚好可以转成一个int）
                    int totalSamples = dataByteSize >> 2;
                    //循环次数
                    int exchangeTimes = totalSamples >> 1;
                    for (int j = 0; j<exchangeTimes; j++) {
                        //交换前后两个采样点，完成逆序
                        uint sampleA = mData[j];
                        uint sampleB = mData[totalSamples-1-j];
                        mData[j] = sampleB;
                        mData[totalSamples-1-j] = sampleA;
                    }
                }
            }
        }
        
    }
    
    return YES;
}



PTS修改如下：
- (FUSampleBuffer)reverseTimingInfoForSampleBuffer:(CMSampleBufferRef)sampleBuffer firstSampleTime:(CMTime)firstSampleTime error:(NSError *__autoreleasing *)error{
    
    FUSampleBuffer fuSampleBuffer;
    
    CMItemCount count;
    OSStatus status =  CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
    CMSampleTimingInfo* pInfo = (CMSampleTimingInfo* )malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleTimingInfo* reversedPInfo = (CMSampleTimingInfo* )malloc(sizeof(CMSampleTimingInfo) * count);
    status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, pInfo, &count);
    
    if (status != 0) {
        *error = [NSError errorWithDomain:[NSString stringWithFormat:@"Failed to get sample timing info array. OSStatus: %d, asset: %@",status,self.assetReader.asset] code:0 userInfo:nil];
        return fuSampleBuffer;
    }else{
        
        for (CMItemCount i = 0; i < count; i++) {
            reversedPInfo[i].duration = pInfo[count - 1 - i].duration;
            reversedPInfo[i].decodeTimeStamp = pInfo[count - 1 - i].decodeTimeStamp;
            reversedPInfo[i].presentationTimeStamp = pInfo[count - 1 - i].presentationTimeStamp;
        }
        
        CMTime firstPresentationTimeStampp = reversedPInfo[0].presentationTimeStamp;
        for (CMItemCount i = 0; i < count; i++) {
            CMTime duration = CMTimeSubtract(firstPresentationTimeStampp, reversedPInfo[i].presentationTimeStamp);
            reversedPInfo[i].presentationTimeStamp = CMTimeAdd(firstSampleTime, duration);
        }
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, count, reversedPInfo, &sout);
    free(pInfo);
    free(reversedPInfo);
    fuSampleBuffer.sampleBuffer = sout;
    return fuSampleBuffer;;
}

---
