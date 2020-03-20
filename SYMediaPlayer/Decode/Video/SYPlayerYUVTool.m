//
//  SYPlayerYUVTool.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerYUVTool.h"
#import <libavutil/imgutils.h>
#import <libavutil/frame.h>
#import <libswscale/swscale.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>


void SYPlayerYUVChannelFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count)
{
    int minWidth = MIN(linesize, width);
    UInt8 * temp = dst;
    memset(dst, 0, dstsize);
    for (int i = 0; i < height; i++) {
        memcpy(temp, src, minWidth * channel_count);
        temp += (minWidth * channel_count);
        src += linesize;
    }
}

UIImage * SYPlayerYUVConvertToImage(UInt8 * src_data[], int src_linesize[], int width, int height, enum AVPixelFormat pixelFormat)
{
    struct SwsContext * sws_context = NULL;
    sws_context = sws_getCachedContext(sws_context, width, height, pixelFormat, width, height,
                                       AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    if (!sws_context)
        return nil;
    
    uint8_t * data[AV_NUM_DATA_POINTERS];
    int linesize[AV_NUM_DATA_POINTERS];
    
    int result = av_image_alloc(data, linesize, width, height, AV_PIX_FMT_RGB24, 1);
    if (result < 0) {
        if (sws_context) {
            sws_freeContext(sws_context);
        }
        return nil;
    }
    
    result = sws_scale(sws_context, (const uint8_t **)src_data, src_linesize, 0, height, data, linesize);
    if (sws_context) {
        sws_freeContext(sws_context);
    }
    if (result < 0)
        return nil;
    if (linesize[0] <= 0 || data[0] == NULL)
        return nil;
    
    CFDataRef dataRef = CFDataCreate(kCFAllocatorDefault, data[0], linesize[0] * height);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(dataRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(width, height, 8, 24, linesize[0], colorSpace,
                                        kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(dataRef);
    av_freep(&data[0]);
    
    if (!imageRef)
        return nil;
    
    UIImage * image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}
