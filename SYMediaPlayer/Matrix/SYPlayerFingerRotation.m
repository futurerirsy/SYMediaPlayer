//
//  SYPlayerFingerRotation.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFingerRotation.h"


@implementation SYPlayerFingerRotation

+ (instancetype)fingerRotation
{
    return [[self alloc] init];
}

+ (CGFloat)degress
{
    return 60.0;
}

- (void)clean
{
    self.x = 0;
    self.y = 0;
}

@end
