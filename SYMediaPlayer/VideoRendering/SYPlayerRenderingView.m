//
//  SYPlayerRenderingView.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerRenderingView.h"
#import "SYPlayerGLViewController.h"
#import "SYPlayerGLFrame.h"
#import "SYPlayerFingerRotation.h"
#import "SYMediaPlayer.h"


@interface SYPlayerRenderingView ()

@property (nonatomic, assign) BOOL avplayerLayerToken;
@property (nonatomic, weak) SYMediaPlayer * abstractPlayer;
@property (nonatomic, strong) AVPlayerLayer * avplayerLayer;
@property (nonatomic, strong) SYPlayerGLViewController * glViewController;

@end


@implementation SYPlayerRenderingView

+ (instancetype)displayViewWithAbstractPlayer:(id)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(id)abstractPlayer
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.abstractPlayer = (SYMediaPlayer *)abstractPlayer;
        self->_fingerRotation = [SYPlayerFingerRotation fingerRotation];
        self.backgroundColor = [UIColor blackColor];
        [self setupEventHandler];
    }
    return self;
}

- (void)setupEventHandler
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidEnterBackgroundAction:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillEnterForegroundAction:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    UITapGestureRecognizer * tapGestureRecigbuzer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iOS_tapGestureRecigbuzerAction:)];
    [self addGestureRecognizer:tapGestureRecigbuzer];
}

- (void)dealloc
{
    [self cleanView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - SYMediaPlayer

- (BOOL)backgroundMode
{
    return self.abstractPlayer.backgroundMode;
}

- (SYVideoType)videoType
{
    return self.abstractPlayer.videoType;
}

- (SYDisplayMode)displayMode
{
    return self.abstractPlayer.displayMode;
}

- (SYGravityMode)viewGravityMode
{
    return self.abstractPlayer.viewGravityMode;
}


#pragma mark - Rendering

- (void)playerOutputTypeEmpty
{
    self->_playerOutputType = SYMediaPlayerOutputTypeEmpty;
}

- (void)playerOutputTypeFF
{
    self->_playerOutputType = SYMediaPlayerOutputTypeFF;
}

- (void)playerOutputTypeAV
{
    self->_playerOutputType = SYMediaPlayerOutputTypeAV;
}

- (void)rendererTypeEmpty
{
    if (self.rendererType != SYVideoRenderingTypeEmpty) {
        self->_rendererType = SYVideoRenderingTypeEmpty;
        [self reloadView];
    }
}

- (void)rendererTypeAVPlayerLayer
{
    if (self.rendererType != SYVideoRenderingTypeAVPlayerLayer) {
        self->_rendererType = SYVideoRenderingTypeAVPlayerLayer;
        [self reloadView];
    }
}

- (void)rendererTypeOpenGL
{
    if (self.rendererType != SYVideoRenderingTypeOpenGL) {
        self->_rendererType = SYVideoRenderingTypeOpenGL;
        [self reloadView];
    }
}


#pragma mark - Reload

- (void)reloadView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cleanView];
        
        switch (self.rendererType) {
            case SYVideoRenderingTypeEmpty:
                break;
            case SYVideoRenderingTypeAVPlayerLayer:
            {
                self.avplayerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
                [self reloadPlayerConfig];
                self.avplayerLayerToken = NO;
                [self.layer insertSublayer:self.avplayerLayer atIndex:0];
                [self reloadGravityMode];
            }
                break;
            case SYVideoRenderingTypeOpenGL:
            {
                self.glViewController = [SYPlayerGLViewController viewControllerWithDisplayView:self];
                SYGLKView * glView = SYGLKViewControllerGetGLView(self.glViewController);
                [self insertSubview:glView atIndex:0];
            }
                break;
        }
        
        [self updateDisplayViewLayout:self.bounds];
    });
}

- (void)reloadGravityMode
{
    if (self.avplayerLayer) {
        switch (self.abstractPlayer.viewGravityMode) {
            case SYGravityModeResize:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResize;
                break;
            case SYGravityModeResizeAspect:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                break;
            case SYGravityModeResizeAspectFill:
                self.avplayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                break;
        }
    }
}

- (void)reloadPlayerConfig
{
    if (self.avplayerLayer && self.playerOutputType == SYMediaPlayerOutputTypeAV) {
        if ([self.playerOutputAV playerOutputGetAVPlayer]
            && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            self.avplayerLayer.player = [self.playerOutputAV playerOutputGetAVPlayer];
        }
        else {
            self.avplayerLayer.player = nil;
        }
    }
}

- (void)reloadVideoFrameForGLFrame:(SYPlayerGLFrame *)glFrame
{
    switch (self.playerOutputType) {
        case SYMediaPlayerOutputTypeEmpty:
            break;
        case SYMediaPlayerOutputTypeAV:
        {
            CVPixelBufferRef pixelBuffer = [self.playerOutputAV playerOutputGetPixelBufferAtCurrentTime];
            if (pixelBuffer) {
                [glFrame updateWithCVPixelBuffer:pixelBuffer];
            }
        }
            break;
        case SYMediaPlayerOutputTypeFF:
        {
            SYPlayerVideoFrame * videoFrame =
            [self.playerOutputFF playerOutputGetVideoFrameWithCurrentPostion:glFrame.currentPosition
                                                             currentDuration:glFrame.currentDuration];
            if (videoFrame) {
                [glFrame updateWithSYPlayerVideoFrame:videoFrame];
                glFrame.rotateType = videoFrame.rotateType;
            }
        }
            break;
    }
}

- (UIImage *)snapshot
{
    switch (self.rendererType) {
        case SYVideoRenderingTypeEmpty:
            return nil;
        case SYVideoRenderingTypeAVPlayerLayer:
            return [self.playerOutputAV playerOutputGetSnapshotAtCurrentTime];
        case SYVideoRenderingTypeOpenGL:
            return [self.glViewController snapshot];
    }
}

- (void)cleanView
{
    if (self.avplayerLayer) {
        [self.avplayerLayer removeFromSuperlayer];
        self.avplayerLayer.player = nil;
        self.avplayerLayer = nil;
    }
    if (self.glViewController) {
        SYGLKView * glView = SYGLKViewControllerGetGLView(self.glViewController);
        [glView removeFromSuperview];
        self.glViewController = nil;
    }
    self.avplayerLayerToken = NO;
    [self.fingerRotation clean];
}

- (void)updateDisplayViewLayout:(CGRect)frame
{
    if (self.avplayerLayer) {
        self.avplayerLayer.frame = frame;
        if (self.abstractPlayer.viewAnimationHidden || !self.avplayerLayerToken) {
            [self.avplayerLayer removeAllAnimations];
            self.avplayerLayerToken = YES;
        }
    }
    if (self.glViewController) {
        [self.glViewController reloadViewport];
    }
}


#pragma mark - Envent

- (void)onDidEnterBackgroundAction:(NSNotification *)notification
{
    if (_avplayerLayer) {
        _avplayerLayer.player = nil;
    }
}

- (void)onWillEnterForegroundAction:(NSNotification *)notification
{
    if (_avplayerLayer) {
        _avplayerLayer.player = [self.playerOutputAV playerOutputGetAVPlayer];
    }
}

- (void)iOS_tapGestureRecigbuzerAction:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.abstractPlayer.viewTapAction) {
        self.abstractPlayer.viewTapAction(self.abstractPlayer, self.abstractPlayer.displayView);
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.abstractPlayer.displayMode == SYDisplayModeBox || self.abstractPlayer.backgroundMode)
        return;
    
    switch (self.rendererType) {
        case SYVideoRenderingTypeEmpty:
        case SYVideoRenderingTypeAVPlayerLayer:
            return;
        default:
        {
            UITouch * touch = [touches anyObject];
            float distanceX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
            float distanceY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
            distanceX *= 0.005;
            distanceY *= 0.005;
            self.fingerRotation.x += distanceY *  [SYPlayerFingerRotation degress] / 100;
            self.fingerRotation.y -= distanceX *  [SYPlayerFingerRotation degress] / 100;
        }
            break;
    }
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    [self updateDisplayViewLayout:layer.bounds];
}

@end
