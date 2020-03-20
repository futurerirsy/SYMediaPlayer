//
//  SYGLKView.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYEAGLContext.h"

typedef GLKView SYGLKView;


@protocol SYGLKViewDelegate <GLKViewDelegate>
- (void)glkView:(SYGLKView *)view drawInRect:(CGRect)rect;
@end


SYEAGLContext * SYGLKViewGetContext(SYGLKView * view);
void SYGLKViewPrepareOpenGL(SYGLKView * view);
void SYGLKViewDisplay(SYGLKView * view);
void SYGLKViewSetDrawDelegate(SYGLKView * view, id <SYGLKViewDelegate> drawDelegate);
void SYGLKViewSetContext(SYGLKView * view, SYEAGLContext * context);
void SYGLKViewBindFrameBuffer(SYGLKView * view);
void SYGLKViewFlushBuffer(SYGLKView * view);
UIImage * SYGLKViewGetCurrentSnapshot(SYGLKView * view);
