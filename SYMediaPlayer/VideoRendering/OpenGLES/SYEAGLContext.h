//
//  SYEAGLContext.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef EAGLContext SYEAGLContext;


SYEAGLContext * SYEAGLContextAllocInit(void);
void SYEAGLContextSetCurrentContext(SYEAGLContext * context);
