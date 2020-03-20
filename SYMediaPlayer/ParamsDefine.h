//
//  ParamsDefine.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/15.
//  Copyright © 2020 RYB. All rights reserved.
//

#ifndef ParamsDefine_h
#define ParamsDefine_h


#define SYMediaPlayerErrorNotification              (@"SYMediaPlayerErrorNotification")
#define SYMediaPlayerStateChangeNotification        (@"SYMediaPlayerStateChangeNotification")
#define SYMediaPlayerProgressChangeNotification     (@"SYMediaPlayerProgressChangeNotification")
#define SYMediaPlayerPlayableChangeNotification     (@"SYMediaPlayerPlayableChangeNotification")

#define SYMediaPlayerPreviousNotificationKey        (@"Previous")
#define SYMediaPlayerCurrentNotificationKey         (@"Current")
#define SYMediaPlayerPercentNotificationKey         (@"Percent")
#define SYMediaPlayerTotalNotificationKey           (@"Total")
#define SYMediaPlayerErrorNotificationKey           (@"Error")


// video type
typedef NS_ENUM(NSUInteger, SYVideoType) {
    SYVideoTypeNormal,  // normal
    SYVideoTypeVR,      // virtual reality
};

// display mode
typedef NS_ENUM(NSUInteger, SYDisplayMode) {
    SYDisplayModeNormal,  // default
    SYDisplayModeBox,
};

// video content mode
typedef NS_ENUM(NSUInteger, SYGravityMode) {
    SYGravityModeResize,
    SYGravityModeResizeAspect,
    SYGravityModeResizeAspectFill,
};

// rendering type
typedef NS_ENUM(NSUInteger, SYVideoRenderingType) {
    SYVideoRenderingTypeEmpty,
    SYVideoRenderingTypeAVPlayerLayer,
    SYVideoRenderingTypeOpenGL,
};

// player type
typedef NS_ENUM(NSUInteger, SYMediaPlayerOutputType) {
    SYMediaPlayerOutputTypeEmpty,
    SYMediaPlayerOutputTypeFF,
    SYMediaPlayerOutputTypeAV,
};

// player state
typedef NS_ENUM(NSUInteger, SYPlayerState) {
    SYPlayerStateNone = 0,          // none
    SYPlayerStateBuffering = 1,     // buffering
    SYPlayerStateReadyToPlay = 2,   // ready to play
    SYPlayerStatePlaying = 3,       // playing
    SYPlayerStateSuspend = 4,       // pause
    SYPlayerStateFinished = 5,      // finished
    SYPlayerStateFailed = 6,        // failed
};


#endif /* ParamsDefine_h */
