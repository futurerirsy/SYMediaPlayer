//
//  SYPlayerGLViewController.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLViewController.h"
#import "SYPlayerRenderingView.h"
#import "SYPlayerDistortionRenderer.h"
#import "SYPlayerGLProgramNV12.h"
#import "SYPlayerGLProgramYUV420.h"
#import "SYPlayerGLTextureNV12.h"
#import "SYPlayerGLTextureYUV420.h"
#import "SYPlayerGLNormalModel.h"
#import "SYPlayerGLVRModel.h"
#import "SYPlayerGLFrame.h"
#import "SYPlayerMatrix.h"


@interface SYPlayerGLViewController ()

@property (nonatomic, weak, readonly) SYPlayerRenderingView * displayView;
@property (nonatomic, strong) SYPlayerDistortionRenderer * distorionRenderer;
@property (nonatomic, strong) SYPlayerGLTextureNV12 * textureNV12;
@property (nonatomic, strong) SYPlayerGLTextureYUV420 * textureYUV420;
@property (nonatomic, strong) SYPlayerGLProgramNV12 * programNV12;
@property (nonatomic, strong) SYPlayerGLProgramYUV420 * programYUV420;
@property (nonatomic, strong) SYPlayerGLNormalModel * normalModel;
@property (nonatomic, strong) SYPlayerGLVRModel * vrModel;
@property (nonatomic, strong) SYPlayerGLFrame * currentFrame;
@property (nonatomic, strong) SYPlayerMatrix * vrMatrix;

@property (nonatomic, strong) NSLock * openGLLock;
@property (nonatomic, assign) BOOL clearToken;
@property (nonatomic, assign) BOOL drawToekn;
@property (nonatomic, assign) CGFloat aspect;
@property (nonatomic, assign) CGRect viewport;

@end


@implementation SYPlayerGLViewController

+ (instancetype)viewControllerWithDisplayView:(id)displayView
{
    return [[self alloc] initWithDisplayView:displayView];
}

- (instancetype)initWithDisplayView:(id)displayView
{
    if (self = [super init]) {
        self->_displayView = (SYPlayerRenderingView *)displayView;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupOpenGL];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat scale = [UIScreen mainScreen].scale;
    SYGLKView * glView = SYGLKViewControllerGetGLView(self);
    self.distorionRenderer.viewportSize = CGSizeMake(CGRectGetWidth(glView.bounds) * scale,
                                                     CGRectGetHeight(glView.bounds) * scale);
}

- (void)setupOpenGL
{
    self.openGLLock = [[NSLock alloc] init];
    SYGLKView * glView = SYGLKViewControllerGetGLView(self);
    glView.backgroundColor = [UIColor blackColor];
    
    SYEAGLContext * context = SYEAGLContextAllocInit();
    SYGLKViewSetContext(glView, context);
    SYEAGLContextSetCurrentContext(context);
    
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    glView.contentScaleFactor = [UIScreen mainScreen].scale;
    self.pauseOnWillResignActive = NO;
    self.resumeOnDidBecomeActive = YES;
    
    self.distorionRenderer = [SYPlayerDistortionRenderer distortionRenderer];
    
    self.textureNV12 = [[SYPlayerGLTextureNV12 alloc] initWithContext:context];
    self.textureYUV420 = [[SYPlayerGLTextureYUV420 alloc] init];
    
    self.programNV12 = [SYPlayerGLProgramNV12 program];
    self.programYUV420 = [SYPlayerGLProgramYUV420 program];
    
    self.normalModel = [SYPlayerGLNormalModel model];
    self.vrModel = [SYPlayerGLVRModel model];
    
    self.vrMatrix = [[SYPlayerMatrix alloc] init];
    self.currentFrame = [SYPlayerGLFrame frame];
    self.aspect = 16.0 / 9.0;
    
    SYVideoType videoType = self.displayView.videoType;
    switch (videoType) {
        case SYVideoTypeNormal:
            self.preferredFramesPerSecond = 25;
            break;
        case SYVideoTypeVR:
            self.preferredFramesPerSecond = 60;
            break;
    }
}

- (void)flushClearColor
{
//    NSLog(@"flush .....");
    [self.openGLLock lock];
    self.clearToken = YES;
    self.drawToekn = NO;
    [self.currentFrame flush];
    [self.textureNV12 flush];
    [self.textureYUV420 flush];
    [self.openGLLock unlock];
}

- (void)glkView:(SYGLKView *)view drawInRect:(CGRect)rect
{
    //. openGL그리기
    [self.openGLLock lock];
    
    SYGLKViewPrepareOpenGL(view);
    
    if (self.clearToken) {
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        self.clearToken = NO;
        SYGLKViewFlushBuffer(view);
    }
    else if ([self needDrawOpenGL]) {
        if (self.displayView.backgroundMode) {
            [self.openGLLock unlock];
            return;
        }
        
        SYGLKView * glView = SYGLKViewControllerGetGLView(self);
        self.viewport = glView.bounds;
        [self drawOpenGL];
        [self.currentFrame didDraw];
        self.drawToekn = YES;
        SYGLKViewFlushBuffer(view);
    }
    
    [self.openGLLock unlock];
}

- (SYPlayerGLProgram *)chooseProgram
{
    switch (self.currentFrame.type) {
        case SYPlayerGLFrameTypeNV12:
            return self.programNV12;
        case SYPlayerGLFrameTypeYUV420:
            return self.programYUV420;
    }
}

- (SYPlayerGLTexture *)chooseTexture
{
    switch (self.currentFrame.type) {
        case SYPlayerGLFrameTypeNV12:
            return self.textureNV12;
        case SYPlayerGLFrameTypeYUV420:
            return self.textureYUV420;
    }
}

- (SYPlayerGLModelTextureRotateType)chooseModelTextureRotateType
{
    switch (self.currentFrame.rotateType) {
        case SYPlayerVideoFrameRotateType0:
            return SYPlayerGLModelTextureRotateType0;
        case SYPlayerVideoFrameRotateType90:
            return SYPlayerGLModelTextureRotateType90;
        case SYPlayerVideoFrameRotateType180:
            return SYPlayerGLModelTextureRotateType180;
        case SYPlayerVideoFrameRotateType270:
            return SYPlayerGLModelTextureRotateType270;
    }
    return SYPlayerGLModelTextureRotateType0;
}

- (BOOL)needDrawOpenGL
{
    [self.displayView reloadVideoFrameForGLFrame:self.currentFrame];
    
    if (!self.currentFrame.hasData) {
        return NO;
    }
    if (self.displayView.videoType != SYVideoTypeVR
        && !self.currentFrame.hasUpate && self.drawToekn) {
        return NO;
    }
    
    SYPlayerGLTexture * texture = [self chooseTexture];
    CGFloat aspect = 16.0 / 9.0;
    if (![texture updateTextureWithGLFrame:self.currentFrame aspect:&aspect]) {
        return NO;
    }
    
    if (self.displayView.videoType == SYVideoTypeVR) {
        self.aspect = 16.0 / 9.0;
    }
    else {
        self.aspect = aspect;
    }
    
    if (self.currentFrame.hasUpdateRotateType) {
        [self reloadViewport];
    }
    
    return YES;
}

- (void)drawOpenGL
{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    SYVideoType videoType = self.displayView.videoType;
    SYDisplayMode displayMode = self.displayView.displayMode;
    
    if (videoType == SYVideoTypeVR && displayMode == SYDisplayModeBox) {
        [self.distorionRenderer beforDrawFrame];
    }
    
    SYPlayerGLProgram * program = [self chooseProgram];
    [program use];
    [program bindVariable];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGRect rect = CGRectMake(0, 0, self.viewport.size.width * scale, self.viewport.size.height * scale);
    switch (videoType) {
        case SYVideoTypeNormal:
        {
            [self.normalModel bindPositionLocation:program.position_location
                              textureCoordLocation:program.texture_coord_location
                                 textureRotateType:[self chooseModelTextureRotateType]];
            glViewport((GLint)rect.origin.x, (GLint)rect.origin.y,
                       (GLsizei)CGRectGetWidth(rect),  (GLsizei)CGRectGetHeight(rect));
            [program updateMatrix:GLKMatrix4Identity];
            glDrawElements(GL_TRIANGLES, self.normalModel.index_count, GL_UNSIGNED_SHORT, 0);
        }
            break;
        case SYVideoTypeVR:
        {
            [self.vrModel bindPositionLocation:program.position_location
                          textureCoordLocation:program.texture_coord_location];
            switch (displayMode) {
                case SYDisplayModeNormal:
                {
                    GLKMatrix4 matrix;
                    BOOL success = [self.vrMatrix singleMatrixWithSize:rect.size matrix:&matrix
                                                        fingerRotation:self.displayView.fingerRotation];
                    if (success) {
                        glViewport((GLint)rect.origin.x, (GLint)rect.origin.y,
                                   (GLsizei)CGRectGetWidth(rect), (GLsizei)CGRectGetHeight(rect));
                        [program updateMatrix:matrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
                case SYDisplayModeBox:
                {
                    GLKMatrix4 leftMatrix;
                    GLKMatrix4 rightMatrix;
                    BOOL success = [self.vrMatrix doubleMatrixWithSize:rect.size
                                                            leftMatrix:&leftMatrix
                                                           rightMatrix:&rightMatrix];
                    if (success) {
                        glViewport((GLint)rect.origin.x, (GLint)rect.origin.y,
                                   (GLsizei)(CGRectGetWidth(rect) / 2), (GLsizei)CGRectGetHeight(rect));
                        [program updateMatrix:leftMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                        
                        glViewport((GLint)(CGRectGetWidth(rect) / 2 + rect.origin.x), (GLint)rect.origin.y,
                                   (GLsizei)(CGRectGetWidth(rect) / 2), (GLsizei)CGRectGetHeight(rect));
                        [program updateMatrix:rightMatrix];
                        glDrawElements(GL_TRIANGLES, self.vrModel.index_count, GL_UNSIGNED_SHORT, 0);
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
    
    if (videoType == SYVideoTypeVR && displayMode == SYDisplayModeBox) {
        SYGLKView * glView = SYGLKViewControllerGetGLView(self);
        SYGLKViewBindFrameBuffer(glView);
        [self.distorionRenderer afterDrawFrame];
    }
}

- (void)reloadViewport
{
    SYGLKView * glView = SYGLKViewControllerGetGLView(self);
    CGRect superviewFrame = glView.superview.bounds;
    CGFloat superviewAspect = superviewFrame.size.width / superviewFrame.size.height;
    
    if (self.aspect <= 0) {
        glView.frame = superviewFrame;
        return;
    }
    
    CGFloat resultAspect = self.aspect;
    switch (self.currentFrame.rotateType) {
        case SYPlayerVideoFrameRotateType90:
        case SYPlayerVideoFrameRotateType270:
            resultAspect = 1 / self.aspect;
            break;
        case SYPlayerVideoFrameRotateType0:
        case SYPlayerVideoFrameRotateType180:
            break;
    }
    
    SYGravityMode gravityMode = self.displayView.viewGravityMode;
    switch (gravityMode) {
        case SYGravityModeResize:
            glView.frame = superviewFrame;
            break;
        case SYGravityModeResizeAspect:
            if (superviewAspect < resultAspect) {
                CGFloat height = superviewFrame.size.width / resultAspect;
                glView.frame = CGRectMake(0, (superviewFrame.size.height - height) / 2,
                                          superviewFrame.size.width, height);
            }
            else if (superviewAspect > resultAspect) {
                CGFloat width = superviewFrame.size.height * resultAspect;
                glView.frame = CGRectMake((superviewFrame.size.width - width) / 2, 0,
                                          width, superviewFrame.size.height);
            }
            else {
                glView.frame = superviewFrame;
            }
            break;
        case SYGravityModeResizeAspectFill:
            if (superviewAspect < resultAspect) {
                CGFloat width = superviewFrame.size.height * resultAspect;
                glView.frame = CGRectMake(-(width - superviewFrame.size.width) / 2, 0,
                                          width, superviewFrame.size.height);
            }
            else if (superviewAspect > resultAspect) {
                CGFloat height = superviewFrame.size.width / resultAspect;
                glView.frame = CGRectMake(0, -(height - superviewFrame.size.height) / 2,
                                          superviewFrame.size.width, height);
            }
            else {
                glView.frame = superviewFrame;
            }
            break;
        default:
            glView.frame = superviewFrame;
            break;
    }
    
    self.drawToekn = NO;
    [self.currentFrame didUpdateRotateType];
}

- (void)setAspect:(CGFloat)aspect
{
    if (_aspect != aspect) {
        _aspect = aspect;
        [self reloadViewport];
    }
}

- (UIImage *)snapshot
{
    if (self.displayView.videoType == SYVideoTypeVR) {
        SYGLKView * glView = SYGLKViewControllerGetGLView(self);
        return SYGLKViewGetCurrentSnapshot(glView);
    }
    else {
        UIImage * image = [self.currentFrame imageFromVideoFrame];
        if (image) {
            return image;
        }
    }
    
    SYGLKView * glView = SYGLKViewControllerGetGLView(self);
    return SYGLKViewGetCurrentSnapshot(glView);
}

- (void)dealloc
{
    SYEAGLContextSetCurrentContext(nil);
    NSLog(@"%@ dealloc", self.class);
}

@end
