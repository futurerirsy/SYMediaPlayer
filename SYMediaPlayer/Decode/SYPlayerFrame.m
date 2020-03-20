//
//  SYPlayerFrame.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFrame.h"


@implementation SYPlayerFrame

- (void)startPlaying
{
    self->_playing = YES;
    if ([self.delegate respondsToSelector:@selector(frameDidStartPlaying:)]) {
        [self.delegate frameDidStartPlaying:self];
    }
}

- (void)stopPlaying
{
    self->_playing = NO;
    if ([self.delegate respondsToSelector:@selector(frameDidStopPlaying:)]) {
        [self.delegate frameDidStopPlaying:self];
    }
}

- (void)cancel
{
    self->_playing = NO;
    if ([self.delegate respondsToSelector:@selector(frameDidCancel:)]) {
        [self.delegate frameDidCancel:self];
    }
}

@end


@implementation SYPlayerSubtileFrame

- (SYPlayerFrameType)type
{
    return SYPlayerFrameTypeSubtitle;
}

@end


@implementation SYPlayerArtworkFrame

- (SYPlayerFrameType)type
{
    return SYPlayerFrameTypeArtwork;
}

@end
