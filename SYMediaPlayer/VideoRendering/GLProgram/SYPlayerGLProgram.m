//
//  SYPlayerGLProgram.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLProgram.h"


@interface SYPlayerGLProgram ()
{
    GLuint _vertexShader_id;
    GLuint _fragmentShader_id;
}

@property (nonatomic, copy) NSString * vertexShaderString;
@property (nonatomic, copy) NSString * fragmentShaderString;

@end


@implementation SYPlayerGLProgram

+ (instancetype)programWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    return [[self alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader];
}

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    if (self = [super init]) {
        self.vertexShaderString = vertexShader;
        self.fragmentShaderString = fragmentShader;
        [self setup];
        [self use];
        [self bindVariable];
    }
    return self;
}

- (void)use
{
    glUseProgram(_program_id);
}

- (void)updateMatrix:(GLKMatrix4)matrix
{
    glUniformMatrix4fv(self.matrix_location, 1, GL_FALSE, matrix.m);
}

- (void)setup
{
    [self setupProgram];
    [self setupShader];
    [self linkProgram];
    [self setupVariable];
}

- (void)setupProgram
{
    _program_id = glCreateProgram();
}

- (void)setupShader
{
    // setup shader
    if (![self compileShader:&_vertexShader_id type:GL_VERTEX_SHADER string:self.vertexShaderString.UTF8String])
    {
        NSLog(@"load vertex shader failure");
    }
    if (![self compileShader:&_fragmentShader_id type:GL_FRAGMENT_SHADER string:self.fragmentShaderString.UTF8String])
    {
        NSLog(@"load fragment shader failure");
    }
    glAttachShader(_program_id, _vertexShader_id);
    glAttachShader(_program_id, _fragmentShader_id);
}

- (BOOL)linkProgram
{
    GLint status;
    glLinkProgram(_program_id);
    
    glGetProgramiv(_program_id, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    [self clearShader];
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const char *)shaderString
{
    if (!shaderString)
    {
        NSLog(@"Failed to load shader");
        return NO;
    }
    
    GLint status;
    
    * shader = glCreateShader(type);
    glShaderSource(* shader, 1, &shaderString, NULL);
    glCompileShader(* shader);
    glGetShaderiv(* shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(* shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar * log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(* shader, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

- (void)clearShader
{
    if (_vertexShader_id) {
        glDeleteShader(_vertexShader_id);
    }
    
    if (_fragmentShader_id) {
        glDeleteShader(_fragmentShader_id);
    }
}

- (void)clearProgram
{
    if (_program_id) {
        glDeleteProgram(_program_id);
        _program_id = 0;
    }
}

- (void)dealloc
{
    [self clearShader];
    [self clearProgram];
}

#pragma mark - subclass override

- (void)bindVariable {}
- (void)setupVariable {}

@end
