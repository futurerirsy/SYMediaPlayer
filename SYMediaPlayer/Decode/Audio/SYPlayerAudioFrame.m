//
//  SYPlayerAudioFrame.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerAudioFrame.h"


@implementation SYPlayerAudioFrame
{
    size_t buffer_size;
}


- (SYPlayerFrameType)type
{
    return SYPlayerFrameTypeAudio;
}

- (int)size
{
    return (int)self->length;
}

- (void)setSamplesLength:(NSUInteger)samplesLength
{
    if (self->buffer_size < samplesLength) {
        if (self->buffer_size > 0 && self->samples != NULL) {
            free(self->samples);
        }
        
        self->buffer_size = samplesLength;
        self->samples = malloc(self->buffer_size);
    }
    
    self->length = (int)samplesLength;
    self->output_offset = 0;
}

- (void)dealloc
{
    if (self->buffer_size > 0 && self->samples != NULL) {
        free(self->samples);
    }
}

@end
