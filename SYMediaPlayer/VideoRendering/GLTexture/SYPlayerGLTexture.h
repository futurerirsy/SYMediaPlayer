//
//  SYPlayerGLTexture.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLFrame.h"
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerGLTexture : NSObject

- (BOOL)updateTextureWithGLFrame:(SYPlayerGLFrame *)glFrame aspect:(CGFloat *)aspect;
- (void)flush;

@end

NS_ASSUME_NONNULL_END
