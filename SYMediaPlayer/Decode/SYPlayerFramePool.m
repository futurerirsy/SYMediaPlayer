//
//  SYPlayerFramePool.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFramePool.h"


@interface SYPlayerFramePool () <SYPlayerFrameDelegate>

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) Class frameClassName;
@property (nonatomic, strong) SYPlayerFrame * playingFrame;
@property (nonatomic, strong) NSMutableSet <SYPlayerFrame *> * unuseFrames;
@property (nonatomic, strong) NSMutableSet <SYPlayerFrame *> * usedFrames;

@end


@implementation SYPlayerFramePool

+ (instancetype)videoPool
{
    return [self poolWithCapacity:60 frameClassName:NSClassFromString(@"SYPlayerAVYUVVideoFrame")];
}

+ (instancetype)audioPool
{
    return [self poolWithCapacity:500 frameClassName:NSClassFromString(@"SYPlayerAudioFrame")];
}

+ (instancetype)poolWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName
{
    return [[self alloc] initWithCapacity:number frameClassName:frameClassName];
}

- (instancetype)initWithCapacity:(NSUInteger)number frameClassName:(Class)frameClassName
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.frameClassName = frameClassName;
        self.unuseFrames = [NSMutableSet setWithCapacity:number];
        self.usedFrames = [NSMutableSet setWithCapacity:number];
    }
    return self;
}

- (NSUInteger)count
{
    return [self unuseCount] + [self usedCount] + (self.playingFrame ? 1 : 0);
}

- (NSUInteger)unuseCount
{
    return self.unuseFrames.count;
}

- (NSUInteger)usedCount
{
    return self.usedFrames.count;
}

- (__kindof SYPlayerFrame *)getUnuseFrame
{
    [self.lock lock];
    
    SYPlayerFrame * frame;
    if (self.unuseFrames.count > 0) {
        frame = [self.unuseFrames anyObject];
        [self.unuseFrames removeObject:frame];
        [self.usedFrames addObject:frame];
    }
    else {
        frame = [[self.frameClassName alloc] init];
        frame.delegate = self;
        [self.usedFrames  addObject:frame];
    }
    
    [self.lock unlock];
    
    return frame;
}

- (void)setFrameUnuse:(SYPlayerFrame *)frame
{
    if (!frame)
        return;
    if (![frame isKindOfClass:self.frameClassName])
        return;
    
    [self.lock lock];
    [self.unuseFrames addObject:frame];
    [self.usedFrames removeObject:frame];
    [self.lock unlock];
}

- (void)setFramesUnuse:(NSArray <SYPlayerFrame *> *)frames
{
    if (frames.count <= 0)
        return;
    
    [self.lock lock];
    for (SYPlayerFrame * obj in frames) {
        if (![obj isKindOfClass:self.frameClassName])
            continue;
        
        [self.usedFrames removeObject:obj];
        [self.unuseFrames addObject:obj];
    }
    [self.lock unlock];
}

- (void)setFrameStartDrawing:(SYPlayerFrame *)frame
{
    if (!frame)
        return;
    if (![frame isKindOfClass:self.frameClassName])
        return;
    
    [self.lock lock];
    
    if (self.playingFrame) {
        [self.unuseFrames addObject:self.playingFrame];
    }
    
    self.playingFrame = frame;
    [self.usedFrames removeObject:self.playingFrame];
    
    [self.lock unlock];
}

- (void)setFrameStopDrawing:(SYPlayerFrame *)frame
{
    if (!frame)
        return;
    if (![frame isKindOfClass:self.frameClassName])
        return;
    
    [self.lock lock];
    if (self.playingFrame == frame) {
        [self.unuseFrames addObject:self.playingFrame];
        self.playingFrame = nil;
    }
    [self.lock unlock];
}

- (void)flush
{
    [self.lock lock];
    [self.usedFrames enumerateObjectsUsingBlock:^(SYPlayerFrame * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.unuseFrames addObject:obj];
    }];
    [self.usedFrames removeAllObjects];
    [self.lock unlock];
}

#pragma mark - SGFFFrameDelegate

- (void)frameDidStartPlaying:(SYPlayerFrame *)frame
{
    [self setFrameStartDrawing:frame];
}

- (void)frameDidStopPlaying:(SYPlayerFrame *)frame
{
    [self setFrameStopDrawing:frame];
}

- (void)frameDidCancel:(SYPlayerFrame *)frame
{
    [self setFrameUnuse:frame];
}


@end
