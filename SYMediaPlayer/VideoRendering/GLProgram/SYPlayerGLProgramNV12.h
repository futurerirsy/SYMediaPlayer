//
//  SYPlayerGLProgramNV12.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLProgram.h"

NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerGLProgramNV12 : SYPlayerGLProgram

+ (instancetype)program;

@property (nonatomic, assign) GLint samplerY_location;
@property (nonatomic, assign) GLint samplerUV_location;
@property (nonatomic, assign) GLint colorConversionMatrix_location;

@end

NS_ASSUME_NONNULL_END
