//
//  SYPlayerFFMetadata.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/18.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYPlayerFFTools.h"


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerFFMetadata : NSObject

+ (instancetype)metadataWithAVDictionary:(AVDictionary *)avDictionary;

@property (nonatomic, strong) NSDictionary * metadata;
@property (nonatomic, copy) NSString * language;
@property (nonatomic, copy) NSString * duration;
@property (nonatomic, assign) long long BPS;
@property (nonatomic, assign) long long number_of_bytes;
@property (nonatomic, assign) long long number_of_frames;

@end

NS_ASSUME_NONNULL_END
