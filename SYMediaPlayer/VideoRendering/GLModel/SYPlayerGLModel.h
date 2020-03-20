//
//  SYPlayerGLModel.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef NS_ENUM(NSUInteger, SYPlayerGLModelTextureRotateType) {
    SYPlayerGLModelTextureRotateType0,
    SYPlayerGLModelTextureRotateType90,
    SYPlayerGLModelTextureRotateType180,
    SYPlayerGLModelTextureRotateType270,
};


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerGLModel : NSObject

+ (instancetype)model;

@property (nonatomic, assign) GLuint index_id;
@property (nonatomic, assign) GLuint vertex_id;
@property (nonatomic, assign) GLuint texture_id;

@property (nonatomic, assign) int index_count;
@property (nonatomic, assign) int vertex_count;

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation;

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(SYPlayerGLModelTextureRotateType)textureRotateType;

- (void)setupModel;

@end

NS_ASSUME_NONNULL_END
