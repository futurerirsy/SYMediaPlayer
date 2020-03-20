//
//  SYPlayerAudioManager.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@class SYPlayerAudioManager;


NS_ASSUME_NONNULL_BEGIN


@protocol SYPlayerAudioManagerDelegate <NSObject>

@required
- (void)audioManager:(SYPlayerAudioManager *)audioManager outputData:(float *)outputData
      numberOfFrames:(UInt32)numberOfFrames numberOfChannels:(UInt32)numberOfChannels;
@optional
- (void)audioPlayer:(SYPlayerAudioManager *)audioManager willRender:(const AudioTimeStamp *)timestamp;
- (void)audioPlayer:(SYPlayerAudioManager *)audioManager didRender:(const AudioTimeStamp *)timestamp;

@end


@interface SYPlayerAudioManager : NSObject

@property (nonatomic, weak) id <SYPlayerAudioManagerDelegate> delegate;
@property (nonatomic, assign) float rate;
@property (nonatomic, assign) float pitch;
@property (nonatomic, assign) float volume;
@property (nonatomic) AudioStreamBasicDescription asbd;

@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) UInt32 numberOfChannels;

- (BOOL)isPlaying;
- (void)play;
- (void)pause;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
