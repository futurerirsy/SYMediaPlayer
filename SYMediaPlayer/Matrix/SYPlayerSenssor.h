//
//  SYPlayerSenssor.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <GLKit/GLKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerSenssor : NSObject

@property (nonatomic, assign, readonly, getter=isReady) BOOL ready;

- (void)start;
- (void)stop;

- (GLKMatrix4)modelView;

@end

NS_ASSUME_NONNULL_END
