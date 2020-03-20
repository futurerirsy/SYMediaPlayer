//
//  SYPlayerMatrix.h
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerFingerRotation.h"
#import <GLKit/GLKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface SYPlayerMatrix : NSObject

- (BOOL)singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix fingerRotation:(SYPlayerFingerRotation *)fingerRotation;
- (BOOL)doubleMatrixWithSize:(CGSize)size leftMatrix:(GLKMatrix4 *)leftMatrix rightMatrix:(GLKMatrix4 *)rightMatrix;

@end

NS_ASSUME_NONNULL_END
