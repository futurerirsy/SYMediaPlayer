//
//  SYPlayerFramePool.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFrame.h"
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerFramePool : NSObject

+ (instancetype)videoPool;
+ (instancetype)audioPool;
+ (instancetype)poolWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName;

- (NSUInteger)count;
- (NSUInteger)unuseCount;
- (NSUInteger)usedCount;

- (__kindof SYPlayerFrame *)getUnuseFrame;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
