//
//  SYPlayerGLProgramYUV420.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLProgramYUV420.h"

#define SG_GLES_STRINGIZE(x) #x

static const char vertexShaderString[] = SG_GLES_STRINGIZE
(
 attribute vec4 position;
 attribute vec2 textureCoord;
 uniform mat4 mvp_matrix;
 varying vec2 v_textureCoord;
 
 void main()
 {
    v_textureCoord = textureCoord;
    gl_Position = mvp_matrix * position;
}
 );


static const char fragmentShaderString[] = SG_GLES_STRINGIZE
(
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerU;
 uniform sampler2D SamplerV;
 varying mediump vec2 v_textureCoord;
 
 void main()
 {
    highp float y = texture2D(SamplerY, v_textureCoord).r;
    highp float u = texture2D(SamplerU, v_textureCoord).r - 0.5;
    highp float v = texture2D(SamplerV, v_textureCoord).r - 0.5;
    
    highp float r = y +             1.402 * v;
    highp float g = y - 0.344 * u - 0.714 * v;
    highp float b = y + 1.772 * u;
    
    gl_FragColor = vec4(r , g, b, 1.0);
}
 );


@implementation SYPlayerGLProgramYUV420

+ (instancetype)program
{
    return [self programWithVertexShader:[NSString stringWithUTF8String:vertexShaderString]
                          fragmentShader:[NSString stringWithUTF8String:fragmentShaderString]];
}

- (void)bindVariable
{
    glEnableVertexAttribArray(self.position_location);
    glEnableVertexAttribArray(self.texture_coord_location);
    
    glUniform1i(self.samplerY_location, 0);
    glUniform1i(self.samplerU_location, 1);
    glUniform1i(self.samplerV_location, 2);
}

- (void)setupVariable
{
    self.position_location = glGetAttribLocation(self.program_id, "position");
    self.texture_coord_location = glGetAttribLocation(self.program_id, "textureCoord");
    self.matrix_location = glGetUniformLocation(self.program_id, "mvp_matrix");
    self.samplerY_location = glGetUniformLocation(self.program_id, "SamplerY");
    self.samplerU_location = glGetUniformLocation(self.program_id, "SamplerU");
    self.samplerV_location = glGetUniformLocation(self.program_id, "SamplerV");
}

@end
