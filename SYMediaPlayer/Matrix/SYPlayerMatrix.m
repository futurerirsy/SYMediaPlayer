//
//  SYPlayerMatrix.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerMatrix.h"
#import "SYPlayerSenssor.h"


@interface SYPlayerMatrix ()

@property (nonatomic, strong) SYPlayerSenssor * sensorManager;

@end


@implementation SYPlayerMatrix

- (instancetype)init
{
    if (self = [super init]) {
        [self setupSensors];
    }
    return self;
}

#pragma mark - sensors

- (void)setupSensors
{
    self.sensorManager = [[SYPlayerSenssor alloc] init];
    [self.sensorManager start];
}

- (BOOL)singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix fingerRotation:(SYPlayerFingerRotation *)fingerRotation
{
    if (!self.sensorManager.isReady)
        return NO;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, -fingerRotation.x);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, self.sensorManager.modelView);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, fingerRotation.y);
    
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 mvpMatrix = GLKMatrix4Identity;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians([SYPlayerFingerRotation degress]), aspect, 0.1f, 400.0f);
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    mvpMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);
    mvpMatrix = GLKMatrix4Multiply(mvpMatrix, modelViewMatrix);
    
    *matrix = mvpMatrix;
    
    return YES;
}

- (BOOL)doubleMatrixWithSize:(CGSize)size leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix
{
    if (!self.sensorManager.isReady)
        return NO;
    
    GLKMatrix4 modelViewMatrix = self.sensorManager.modelView;
    
    float aspect = fabs(size.width / 2 / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians([SYPlayerFingerRotation degress]), aspect, 0.1f, 400.0f);
    
    CGFloat distance = 0.012;
    
    GLKMatrix4 leftViewMatrix = GLKMatrix4MakeLookAt(-distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    GLKMatrix4 rightViewMatrix = GLKMatrix4MakeLookAt(distance, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    
    GLKMatrix4 leftMvpMatrix = GLKMatrix4Multiply(projectionMatrix, leftViewMatrix);
    GLKMatrix4 rightMvpMatrix = GLKMatrix4Multiply(projectionMatrix, rightViewMatrix);
    
    leftMvpMatrix = GLKMatrix4Multiply(leftMvpMatrix, modelViewMatrix);
    rightMvpMatrix = GLKMatrix4Multiply(rightMvpMatrix, modelViewMatrix);
    
    * leftMatrix = leftMvpMatrix;
    * rightMatrix = rightMvpMatrix;
    
    return YES;
}

- (void)dealloc
{
    [self.sensorManager stop];
    self.sensorManager = nil;
}

@end
