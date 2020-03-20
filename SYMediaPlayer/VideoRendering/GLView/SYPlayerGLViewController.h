//
//  SYPlayerGLViewController.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYGLKViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerGLViewController : SYGLKViewController

+ (instancetype)viewControllerWithDisplayView:(id)displayView;

- (void)reloadViewport;
- (void)flushClearColor;
- (UIImage *)snapshot;

@end

NS_ASSUME_NONNULL_END
