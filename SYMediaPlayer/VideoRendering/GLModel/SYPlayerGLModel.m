//
//  SYPlayerGLModel.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLModel.h"


@implementation SYPlayerGLModel

+ (instancetype)model
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupModel];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%@ dealloc", self.class);
}

#pragma mark - subclass override

- (void)setupModel
{
    ;
}

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
{
    ;
}
- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(SYPlayerGLModelTextureRotateType)textureRotateType
{
    ;
}

@end
