//
//  SYPlayerDistortionRenderer.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerDistortionRenderer : NSObject

+ (instancetype)distortionRenderer;
- (instancetype)initWithViewportSize:(CGSize)viewportSize;

- (void)beforDrawFrame;
- (void)afterDrawFrame;

@property (nonatomic, assign) CGSize viewportSize;

@end

NS_ASSUME_NONNULL_END
