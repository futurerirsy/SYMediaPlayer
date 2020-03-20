//
//  SYPlayerYUVTool.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <libavutil/pixfmt.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

void SYPlayerYUVChannelFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count);
UIImage * SYPlayerYUVConvertToImage(UInt8 * src_data[], int src_linesize[], int width, int height, enum AVPixelFormat pixelFormat);
