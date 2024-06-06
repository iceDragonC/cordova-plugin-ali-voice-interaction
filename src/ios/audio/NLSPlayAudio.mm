//
//  NLSPlayAudio.mm
//  NuiDemo
//
//  Created by zhouguangdong on 2019/12/4.
//  Copyright © 2019 Alibaba idst. All rights reserved.
//

//#define DEBUG_MODE

#import "NLSPlayAudio.h"
#import "pthread.h"
#import "NLSRingBuffer.h"

static UInt32 gBufferSizeBytes=2048;//It must be pow(2,x)


//RINGBUFFER_NEW(ring_buf, 16000)

@interface NLSPlayAudio() {
    int state;
    NlsRingBuffer* ring_buf;
}

@end

@implementation NLSPlayAudio

- (id) init {
    self = [super init];
    ring_buf = [[NlsRingBuffer alloc] init:16000];

    [self cleanup];
    
    ///设置音频参数
    audioDescription.mSampleRate  = 16000;//采样率Hz
    audioDescription.mFormatID    = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags =  kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsNonInterleaved;
    audioDescription.mChannelsPerFrame = 1;
    audioDescription.mFramesPerPacket  = 1;//每一个packet一侦数据
    audioDescription.mBitsPerChannel   = 16;//av_get_bytes_per_sample(AV_SAMPLE_FMT_S16)*8;//每个采样点16bit量化
    audioDescription.mBytesPerPacket   = 2;
    audioDescription.mBytesPerFrame    = 2;
    audioDescription.mReserved = 0;
    
    //使用player的内部线程播 创建AudioQueue
    AudioQueueNewOutput(&audioDescription, bufferCallback, (__bridge void *)(self), nil, nil, 0, &audioQueue);
    if(audioQueue)
    {
        Float32 gain=1.0;
        //设置音量
        AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, gain);
        ////添加buffer区 创建Buffer
        for(int i=0;i < NUM_BUFFERS; i++) {
            int result = AudioQueueAllocateBuffer(audioQueue, gBufferSizeBytes, &audioQueueBuffers[i]);
            AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffers[i], 0, NULL);
            TLog(@"audioplayer: AudioQueueAllocateBuffer i = %d,result = %d",i,result);
        }
    }
    return self;
}

- (void)primePlayQueueBuffers
{
    for (int t = 0; t < NUM_BUFFERS; ++t)
    {
        TLog(@"audioplayer: buffer %d available size %d", t, audioQueueBuffers[t]->mAudioDataBytesCapacity);
        bufferCallback((__bridge void *)(self), audioQueue, audioQueueBuffers[t]);
    }
    AudioQueuePrime(audioQueue, 0, NULL);
}

- (void)play {
    TLog(@"audioplayer: Audio Play Start >>>>>");
    state = playing;
    [self reset];
    dispatch_async(dispatch_get_main_queue(), ^{
        TLog(@"audioplayer: Audio Play async ...");
        if (audioQueue) {
            [self primePlayQueueBuffers];
            OSStatus status = AudioQueueStart(audioQueue, NULL);
            if (status != 0) {
                AudioQueueFlush(audioQueue);
                status = AudioQueueStart(audioQueue, NULL);
            }
            if (status != 0) {
                TLog(@"audioplayer: 启动queue失败 %d", (int)status);
            }
        } else {
            TLog(@"audioplayer: Audio Play audioQueue is null! >>>>> ");
        }
        TLog(@"audioplayer: Audio Play async finish");
    });
    TLog(@"audioplayer: Audio Play done");
}

- (void)pause {
    state = paused;
    if (audioQueue) {
        AudioQueuePause(audioQueue);
    }
}

- (void)resume {
    state = playing;
    if (audioQueue) {
        AudioQueueStart(audioQueue, NULL);
    }
}
- (void) setstate:(PlayerState)pstate{
    state = pstate;
}


- (int)write:(const char*)buffer Length:(int)len {
    int wait_time_ms = 0;
    int ret = 0;
    while (1) {
        if(wait_time_ms > 3000) {
            TLog(@"wait for 3s, player must not consuming pcm data. overrun...");
            break;
        }
        TLog(@"ringbuf want write data %d",  len);
        int ret = [ring_buf ringbuffer_write:(unsigned char*)buffer Length:len];
//        int ret = ringbuffer_write(&ring_buf, (unsigned char*)buffer, (unsigned int)len);
        TLog(@"ringbuf write data %d",  ret);
        if (state != playing) {
            break;
        }
        if (ret <= 0) {
            usleep(20000);
            wait_time_ms += 20;
            continue;
        } else {
            break;
        }
    }
    return ret;
}

-(void) reset {
    [ring_buf ringbuffer_reset];
//    ringbuffer_reset(&ring_buf);
    if (audioQueue) {
        TLog(@"audioplayer: Flush reset");
        //AudioQueueReset(audioQueue);
        AudioQueueStop(audioQueue, TRUE);
        AudioQueueFlush(audioQueue);
    }
}

-(void)stop {
    TLog(@"audioplayer: Audio Player Stop >>>>>");
    state = idle;
    [self reset];
    TLog(@"audioplayer: Audio Player Stop done");
}

-(void)drain {
    state = draining;
}

-(void)cleanup {
    [ring_buf ringbuffer_reset];
//    ringbuffer_reset(&ring_buf);
    state = idle;
    if(audioQueue)
    {
        TLog(@"audioplayer: Release AudioQueueNewOutput");
        
        AudioQueueFlush(audioQueue);
        AudioQueueReset(audioQueue);
        AudioQueueStop(audioQueue, TRUE);
        for(int i=0; i < QUEUE_BUFFER_SIZE; i++)
        {
            AudioQueueFreeBuffer(audioQueue, audioQueueBuffers[i]);
            audioQueueBuffers[i] = nil;
        }
        audioQueue = nil;
    }
}

//回调函数(Callback)的实现
static void bufferCallback(void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef buffer) {
    NLSPlayAudio* player = (__bridge NLSPlayAudio *)inUserData;
    int ret = [player GetAudioData:buffer];
    if (ret > 0) {
        OSStatus status = AudioQueueEnqueueBuffer(inAQ, buffer, 0, NULL);
        TLog(@"audioplayer: playCallback status %d.", status);
    } else {
        TLog(@"audioplayer: no more data");
        if (player->state == draining) {
            //drain data finish, stop player.
            [player stop];
            if([player->_delegate respondsToSelector:@selector(playerDidFinish)]){
               dispatch_async(dispatch_get_main_queue(), ^{
                   [player->_delegate playerDidFinish];
               });
            }
        }
    }
}

- (int)GetAudioData:(AudioQueueBufferRef)buffer {
    if (buffer == NULL || buffer->mAudioData == NULL) {
        TLog(@"no more data to play");
        return 0;
    }
    while (1) {
        int ret = [ring_buf ringbuffer_read:(unsigned char*)buffer->mAudioData Length:buffer->mAudioDataBytesCapacity];
//        int ret = ringbuffer_read(&ring_buf, (unsigned char*)buffer->mAudioData, buffer->mAudioDataBytesCapacity);
//        TLog(@"ringbuf read data %d;state:%d",  ret, state);

        if (0 < ret) {
            TLog(@"ringbuf read data %d",  ret);
            buffer->mAudioDataByteSize = ret;
            return ret;
        } else {
            if (state != playing) {
                break;
            }
            usleep(10*1000);
            continue;
        }
    }
    return 0;
}

@end
