//
//  SYMediaPlayer+DisplayView.h
//  SYMediaPlayerDemo
//
//  Created by RYB_iMAC on 2020/3/18.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SYPlayerRenderingView.h"


NS_ASSUME_NONNULL_BEGIN

@interface SYMediaPlayer (DisplayView)

@property (nonatomic, strong, readonly) SYPlayerRenderingView * displayView;

@end

NS_ASSUME_NONNULL_END
