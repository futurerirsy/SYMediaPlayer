//
//  SYPlayerFFTrack.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/18.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYPlayerFFMetadata.h"

typedef NS_ENUM(NSUInteger, SYPlayerFFTrackType) {
    SYPlayerFFTrackTypeVideo,
    SYPlayerFFTrackTypeAudio,
    SYPlayerFFTrackTypeSubtitle,
};


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerFFTrack : NSObject

@property (nonatomic, assign) int index;
@property (nonatomic, assign) SYPlayerFFTrackType type;
@property (nonatomic, strong) SYPlayerFFMetadata * metadata;

@end

NS_ASSUME_NONNULL_END
