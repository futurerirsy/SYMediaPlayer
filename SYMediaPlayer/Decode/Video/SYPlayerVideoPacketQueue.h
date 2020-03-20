//
//  SYPlayerVideoPacketQueue.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerVideoPacketQueue : NSObject

+ (instancetype)packetQueueWithTimebase:(NSTimeInterval)timebase;

@property (nonatomic, assign, readonly) NSUInteger count;
@property (nonatomic, assign, readonly) int size;
@property (atomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) NSTimeInterval timebase;

- (void)putPacket:(AVPacket)packet duration:(NSTimeInterval)duration;
- (AVPacket)getPacketSync;
- (AVPacket)getPacketAsync;

- (void)flush;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
