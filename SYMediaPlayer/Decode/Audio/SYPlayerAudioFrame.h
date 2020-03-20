//
//  SYPlayerAudioFrame.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFrame.h"


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerAudioFrame : SYPlayerFrame
{
@public
    float * samples;
    int length;
    int output_offset;
}

- (void)setSamplesLength:(NSUInteger)samplesLength;

@end

NS_ASSUME_NONNULL_END
