//
//  SYGLKViewController.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYGLKView.h"
#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef GLKViewController SYGLKViewController;


SYGLKView * SYGLKViewControllerGetGLView(SYGLKViewController * viewController);
