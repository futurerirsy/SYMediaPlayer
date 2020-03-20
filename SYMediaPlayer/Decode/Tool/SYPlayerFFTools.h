//
//  SYPlayerFFTools.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <libavformat/avformat.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SYPlayerDecoderErrorCode) {
    SYPlayerDecoderErrorCodeFormatCreate,
    SYPlayerDecoderErrorCodeFormatOpenInput,
    SYPlayerDecoderErrorCodeFormatFindStreamInfo,
    SYPlayerDecoderErrorCodeStreamNotFound,
    SYPlayerDecoderErrorCodeCodecContextCreate,
    SYPlayerDecoderErrorCodeCodecContextSetParam,
    SYPlayerDecoderErrorCodeCodecFindDecoder,
    SYPlayerDecoderErrorCodeCodecVideoSendPacket,
    SYPlayerDecoderErrorCodeCodecAudioSendPacket,
    SYPlayerDecoderErrorCodeCodecVideoReceiveFrame,
    SYPlayerDecoderErrorCodeCodecAudioReceiveFrame,
    SYPlayerDecoderErrorCodeCodecOpen2,
    SYPlayerDecoderErrorCodeAuidoSwrInit,
};

void SYPlayerLog(void * context, int level, const char * format, va_list args);

NSError * SYPlayerCheckError(int result);
NSError * SYPlayerCheckErrorCode(int result, NSUInteger errorCode);

double SYPlayerStreamGetTimebase(AVStream * stream, double default_timebase);
double SYPlayerStreamGetFPS(AVStream * stream, double timebase);

NSDictionary * SYPlayerFoundationBrigeOfAVDictionary(AVDictionary * avDictionary);
AVDictionary * SYPlayerFFmpegBrigeOfNSDictionary(NSDictionary * dictionary);
