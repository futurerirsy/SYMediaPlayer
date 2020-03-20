//
//  SYPlayerDistortionModel.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef NS_ENUM(NSUInteger, SYPlayerDistortionModelType) {
    SYPlayerDistortionModelTypeLeft,
    SYPlayerDistortionModelTypeRight,
};


NS_ASSUME_NONNULL_BEGIN


@interface SYPlayerDistortionModel : NSObject

+ (instancetype)modelWithModelType:(SYPlayerDistortionModelType)modelType;

@property (nonatomic, assign, readonly) SYPlayerDistortionModelType modelType;

@property (nonatomic, assign) int index_count;
@property (nonatomic, assign) GLint index_buffer_id;
@property (nonatomic, assign) GLint vertex_buffer_id;

@end


NS_ASSUME_NONNULL_END
