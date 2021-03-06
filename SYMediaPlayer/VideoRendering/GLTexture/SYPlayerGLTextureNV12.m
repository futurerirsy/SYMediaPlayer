//
//  SYPlayerGLTextureNV12.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLTextureNV12.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface SYPlayerGLTextureNV12 ()

@property (nonatomic, strong) EAGLContext * context;

@property (nonatomic, assign) CVOpenGLESTextureRef lumaTexture;
@property (nonatomic, assign) CVOpenGLESTextureRef chromaTexture;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef videoTextureCache;

@property (nonatomic, assign) CGFloat textureAspect;
@property (nonatomic, assign) BOOL didBindTexture;

@end


@implementation SYPlayerGLTextureNV12

- (instancetype)initWithContext:(EAGLContext *)context
{
    if (self = [super init]) {
        self.context = context;
        [self setupVideoCache];
    }
    return self;
}

- (void)setupVideoCache
{
    if (!self.videoTextureCache) {
        CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (result != noErr) {
            NSLog(@"create CVOpenGLESTextureCacheCreate failure %d", result);
            return;
        }
    }
}

- (BOOL)updateTextureWithGLFrame:(SYPlayerGLFrame *)glFrame aspect:(CGFloat *)aspect
{
    CVPixelBufferRef pixelBuffer = [glFrame pixelBufferForNV12];
    if (pixelBuffer == nil) {
        if (self.lumaTexture && self.chromaTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
            * aspect = self.textureAspect;
            return YES;
        }
        else {
            return NO;
        }
    }
    
    if (!self.videoTextureCache) {
        NSLog(@"no video texture cache");
        return NO;
    }
    
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    self.textureAspect = (textureWidth * 1.0) / (textureHeight * 1.0);
    * aspect = self.textureAspect;
    
    [self cleanTextures];
    
    CVReturn result;
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache,
                                                          pixelBuffer, NULL,
                                                          GL_TEXTURE_2D, GL_RED_EXT,
                                                          textureWidth, textureHeight,
                                                          GL_RED_EXT, GL_UNSIGNED_BYTE,
                                                          0, &_lumaTexture);
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    else {
        NSLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 1 %d", result);
    }
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache,
                                                          pixelBuffer, NULL,
                                                          GL_TEXTURE_2D, GL_RG_EXT,
                                                          textureWidth/2, textureHeight/2,
                                                          GL_RG_EXT, GL_UNSIGNED_BYTE,
                                                          1, &_chromaTexture);
    
    if (result == kCVReturnSuccess) {
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    else {
        NSLog(@"create CVOpenGLESTextureCacheCreateTextureFromImage failure 2 %d", result);
    }
    
    self.didBindTexture = YES;
    return YES;
}

- (void)clearVideoCache
{
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        self.videoTextureCache = nil;
    }
}

- (void)cleanTextures
{
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    self.textureAspect = 16.0 / 9.0;
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc
{
    [self clearVideoCache];
    [self cleanTextures];
}

@end
