//
//  SYGLKView.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYGLKView.h"


SYEAGLContext * SYGLKViewGetContext(SYGLKView * view)
{
    return view.context;
}

void SYGLKViewPrepareOpenGL(SYGLKView * view)
{
    SYEAGLContext * context = SYGLKViewGetContext(view);
    SYEAGLContextSetCurrentContext(context);
}

void SYGLKViewDisplay(SYGLKView * view)
{
    [view display];
}

void SYGLKViewSetDrawDelegate(SYGLKView * view, id <SYGLKViewDelegate> drawDelegate)
{
    view.delegate = drawDelegate;
}

void SYGLKViewSetContext(SYGLKView * view, SYEAGLContext * context)
{
    view.context = context;
}

void SYGLKViewBindFrameBuffer(SYGLKView * view)
{
    [view bindDrawable];
}

void SYGLKViewFlushBuffer(SYGLKView * view)
{
    
}

UIImage * SYGLKViewGetCurrentSnapshot(SYGLKView * view)
{
    return view.snapshot;
}
