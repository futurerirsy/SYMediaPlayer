//
//  SYPlayerGLProgram.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerGLProgram : NSObject

+ (instancetype)programWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;

@property (nonatomic, assign) GLint program_id;
@property (nonatomic, assign) GLint matrix_location;
@property (nonatomic, assign) GLint position_location;
@property (nonatomic, assign) GLint texture_coord_location;

- (void)use;
- (void)updateMatrix:(GLKMatrix4)matrix;

#pragma mark - subclass override

- (void)setupVariable;
- (void)bindVariable;

@end

NS_ASSUME_NONNULL_END
