//
//  SYPlayerDecoder.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>

// decode type
typedef NS_ENUM(NSUInteger, SYDecoderType) {
    SYDecoderTypeError,
    SYDecoderTypeAVPlayer,
    SYDecoderTypeFFmpeg,
};

// media format
typedef NS_ENUM(NSUInteger, SYMediaFormat) {
    SYMediaFormatError,
    SYMediaFormatUnknown,
    SYMediaFormatMP3,
    SYMediaFormatMPEG4,
    SYMediaFormatMOV,
    SYMediaFormatFLV,
    SYMediaFormatM3U8,
    SYMediaFormatRTMP,
    SYMediaFormatRTSP,
};


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerDecoder : NSObject

+ (instancetype)decoderByDefault;
+ (instancetype)decoderByAVPlayer;
+ (instancetype)decoderByFFmpeg;

@property (nonatomic, assign) BOOL hardwareAccelerateEnableForFFmpeg;  // default is YES

@property (nonatomic, assign) SYDecoderType decodeTypeForUnknown;      // default is SYDecoderTypeFFmpeg
@property (nonatomic, assign) SYDecoderType decodeTypeForMP3;          // default is SYDecoderTypeAVPlayer
@property (nonatomic, assign) SYDecoderType decodeTypeForMPEG4;        // default is SYDecoderTypeAVPlayer
@property (nonatomic, assign) SYDecoderType decodeTypeForMOV;          // default is SYDecoderTypeAVPlayer
@property (nonatomic, assign) SYDecoderType decodeTypeForFLV;          // default is SYDecoderTypeFFmpeg
@property (nonatomic, assign) SYDecoderType decodeTypeForM3U8;         // default is SYDecoderTypeAVPlayer
@property (nonatomic, assign) SYDecoderType decodeTypeForRTMP;         // default is SYDecoderTypeFFmpeg
@property (nonatomic, assign) SYDecoderType decodeTypeForRTSP;         // default is SYDecoderTypeFFmpeg

- (SYMediaFormat)mediaFormatForContentURL:(NSURL *)contentURL;
- (SYDecoderType)decoderTypeForContentURL:(NSURL *)contentURL;


#pragma mark - FFmpeg optioins

- (NSDictionary *)FFmpegFormatContextOptions;
- (void)setFFmpegFormatContextOptionIntValue:(int64_t)value forKey:(NSString *)key;
- (void)setFFmpegFormatContextOptionStringValue:(NSString *)value forKey:(NSString *)key;
- (void)removeFFmpegFormatContextOptionForKey:(NSString *)key;

- (NSDictionary *)FFmpegCodecContextOptions;
- (void)setFFmpegCodecContextOptionIntValue:(int64_t)value forKey:(NSString *)key;
- (void)setFFmpegCodecContextOptionStringValue:(NSString *)value forKey:(NSString *)key;
- (void)removeFFmpegCodecContextOptionForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
