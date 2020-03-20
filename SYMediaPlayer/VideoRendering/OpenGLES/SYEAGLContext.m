//
//  SYEAGLContext.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYEAGLContext.h"


SYEAGLContext * SYEAGLContextAllocInit(void)
{
    return [[SYEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
}

void SYEAGLContextSetCurrentContext(SYEAGLContext * context)
{
    [EAGLContext setCurrentContext:context];
}
