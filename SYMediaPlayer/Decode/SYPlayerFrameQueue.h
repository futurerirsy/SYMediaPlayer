//
//  SYPlayerFrameQueue.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFrame.h"
#import <Foundation/Foundation.h>


@interface SYPlayerFrameQueue : NSObject

+ (instancetype)frameQueue;
+ (NSTimeInterval)maxVideoDuration;
+ (NSTimeInterval)sleepTimeIntervalForFull;
+ (NSTimeInterval)sleepTimeIntervalForFullAndPaused;

@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) int packetSize;
@property (nonatomic, assign, readonly) NSUInteger count;
@property (atomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign) NSUInteger minFrameCountForGet;    // default is 1.
@property (nonatomic, assign) BOOL ignoreMinFrameCountForGetLimit;

- (void)putFrame:(__kindof SYPlayerFrame *)frame;
- (void)putSortFrame:(__kindof SYPlayerFrame *)frame;

- (__kindof SYPlayerFrame *)getFrameSync;
- (__kindof SYPlayerFrame *)getFrameAsync;
- (__kindof SYPlayerFrame *)getFrameAsyncPosistion:(NSTimeInterval)position
                                     discardFrames:(NSMutableArray <__kindof SYPlayerFrame *> **)discardFrames;

- (NSTimeInterval)getFirstFramePositionAsync;
- (NSMutableArray <__kindof SYPlayerFrame *> *)discardFrameBeforPosition:(NSTimeInterval)position;

- (void)flush;
- (void)destroy;

@end

