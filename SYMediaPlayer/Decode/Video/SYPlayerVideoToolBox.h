//
//  SYPlayerVideoToolBox.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerVideoToolBox : NSObject

+ (instancetype)videoToolBoxWithCodecContext:(AVCodecContext *)codecContext;

- (BOOL)sendPacket:(AVPacket)packet needFlush:(BOOL *)needFlush;
- (CVImageBufferRef)imageBuffer;

- (BOOL)trySetupVTSession;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
