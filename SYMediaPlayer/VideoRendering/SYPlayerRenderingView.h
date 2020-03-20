//
//  SYPlayerRenderingView.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SYAVPlayer.h"
#import "SYFFMpegPlayer.h"

@class SYPlayerFingerRotation;
@class SYPlayerGLFrame;


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerRenderingView : UIView

+ (instancetype)displayViewWithAbstractPlayer:(id)abstractPlayer;

@property (nonatomic, assign, readonly) BOOL backgroundMode;
@property (nonatomic, assign, readonly) SYVideoType videoType;
@property (nonatomic, assign, readonly) SYDisplayMode displayMode;
@property (nonatomic, assign, readonly) SYGravityMode viewGravityMode;
@property (nonatomic, strong, readonly) SYPlayerFingerRotation * fingerRotation;


// player output type
@property (nonatomic, assign, readonly) SYMediaPlayerOutputType playerOutputType;
@property (nonatomic, weak) id <SYAVPlayerOutput> playerOutputAV;
- (void)playerOutputTypeAV;
- (void)playerOutputTypeEmpty;


//. FFmpeg_Enable
@property (nonatomic, weak) id <SYFFMpegPlayerOutput> playerOutputFF;
- (void)playerOutputTypeFF;


// renderer type
@property (nonatomic, assign, readonly) SYVideoRenderingType rendererType;
- (void)rendererTypeEmpty;
- (void)rendererTypeAVPlayerLayer;
- (void)rendererTypeOpenGL;


// reload
- (void)reloadGravityMode;
- (void)reloadPlayerConfig;
- (void)reloadVideoFrameForGLFrame:(SYPlayerGLFrame *)glFrame;

- (UIImage *)snapshot;

@end

NS_ASSUME_NONNULL_END
