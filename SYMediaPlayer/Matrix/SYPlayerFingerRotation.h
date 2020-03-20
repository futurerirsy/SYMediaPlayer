//
//  SYPlayerFingerRotation.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerFingerRotation : NSObject

+ (instancetype)fingerRotation;
+ (CGFloat)degress;

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;

- (void)clean;

@end

NS_ASSUME_NONNULL_END
