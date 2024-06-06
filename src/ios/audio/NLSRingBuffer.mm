//
//  NLSRingBuffer.m
//  NUI SDK
//
//  Created by joseph.zgd on 21-11-10.
//  Copyright (c) 2021年 Alibaba iDST. All rights reserved.
//

#include <mutex>
#import "NLSRingBuffer.h"



@interface NlsRingBuffer(){
    unsigned char *buffer;
    unsigned int size;
    unsigned int fill;
    unsigned char *read;
    unsigned char *write;
    std::mutex lock;
}
@end

@implementation NlsRingBuffer

-(id) init:(int)size_in_byte {
    std::unique_lock<decltype(lock)> auto_lock(lock);
    buffer = (unsigned char*)malloc(size_in_byte);
    size = size_in_byte;
    fill = 0;
    read = buffer;
    write = buffer;
    return self;
}

-(void)dealloc {
    std::unique_lock<decltype(lock)> auto_lock(lock);
    if (buffer) {
        free(buffer);
    }
}

-(int) ringbuffer_empty {
    if (buffer == nullptr)
        return 1;
    std::unique_lock<decltype(lock)> auto_lock(lock);
    /* It's empty when the read and write pointers are the same. */
    if (0 == fill) {
        return 1;
    }else {
        return 0;
    }
}
-(int)  ringbuffer_full {
    if (buffer == nullptr)
        return 0;
    std::unique_lock<decltype(lock)> auto_lock(lock);
    /* It's full when the write ponter is 1 element before the read pointer*/
    if (size == fill) {
        return 1;
    }else {
        return 0;
    }
}

-(int) ringbuffer_get_write_index {
    if (buffer == nullptr)
        return 0;
    return write - buffer;
}

-(int) ringbuffer_get_read_index{
    if (buffer == nullptr)
        return 0;
    return read - buffer;
}

-(int) ringbuffer_get_filled {
    if (buffer == nullptr)
        return 0;
    int r = [self ringbuffer_get_read_index];
    int w = [self ringbuffer_get_write_index];
    if (w >= r) {
        return w - r;
    } else {
        return w + size - r;
    }
}

-(int)  ringbuffer_read:(unsigned char*)buf Length:(unsigned int)len {
    if (buffer == nullptr)
        return 0;
    std::unique_lock<decltype(lock)> auto_lock(lock);
    assert(len>0);
    if (fill < len) {
        len = fill;
    }
    if (fill >= len) {
        // in one direction, there is enough data for retrieving
        if (write > read) {
            memcpy(buf, read, len);
            read += len;
        }else if (write < read) {
            int len1 = buffer + size - 1 - read + 1;
            if (len1 >= len) {
                memcpy(buf, read, len);
                read += len;
            } else {
                int len2 = len - len1;
                memcpy(buf, read, len1);
                memcpy(buf + len1, buffer, len2);
                read = buffer + len2; // Wrap around
            }
        }
        fill -= len;
        return len;
    } else    {
        return 0;
    }
}
-(int)  ringbuffer_write:(unsigned char*)buf Length:(unsigned int)len {
    if (buffer == nullptr)
        return 0;
    std::unique_lock<decltype(lock)> auto_lock(lock);
//    printf("ringbuffer_write: %d read %d len %d fill %d\n", ringbuffer_get_write_index(rb), ringbuffer_get_read_index(rb), len, rb->fill);
    assert(len > 0);
    if (size - fill <= len) {
        return 0;
    }
    else {
        if (write >= read) {
            int len1 = buffer + size - write;
            if (len1 >= len) {
                memcpy(write, buf, len);
                write += len;
            } else {
                int len2 = len - len1;
                memcpy(write, buf, len1);
                memcpy(buffer, buf+len1, len2);
                write = buffer + len2; // Wrap around
            }
        } else {
            memcpy(write, buf, len);
            write += len;
        }
        fill += len;
        return len;
    }
}
-(void)  ringbuffer_reset {
    std::unique_lock<decltype(lock)> auto_lock(lock);
    if (buffer == nullptr)
        return;
    fill = 0;
    write = buffer;
    read = buffer;
    memset(buffer, 0, size);
    return;
}
@end
