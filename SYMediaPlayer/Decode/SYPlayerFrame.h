//
//  SYPlayerFrame.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SYPlayerFrameType) {
    SYPlayerFrameTypeVideo,
    SYPlayerFrameTypeAVYUVVideo,
    SYPlayerFrameTypeCVYUVVideo,
    SYPlayerFrameTypeAudio,
    SYPlayerFrameTypeSubtitle,
    SYPlayerFrameTypeArtwork,
};

@class SYPlayerFrame;


NS_ASSUME_NONNULL_BEGIN

@protocol SYPlayerFrameDelegate <NSObject>

- (void)frameDidStartPlaying:(SYPlayerFrame *)frame;
- (void)frameDidStopPlaying:(SYPlayerFrame *)frame;
- (void)frameDidCancel:(SYPlayerFrame *)frame;

@end


@interface SYPlayerFrame : NSObject

@property (nonatomic, weak) id <SYPlayerFrameDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL playing;

@property (nonatomic, assign) SYPlayerFrameType type;
@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign) int packetSize;

- (void)startPlaying;
- (void)stopPlaying;
- (void)cancel;

@end


@interface SYPlayerSubtileFrame : SYPlayerFrame

@end


@interface SYPlayerArtworkFrame : SYPlayerFrame

@property (nonatomic, strong) NSData * picture;

@end

NS_ASSUME_NONNULL_END
