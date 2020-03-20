//
//  SYPlayerGLNormalModel.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerGLNormalModel.h"


static GLKVector3 vertex_buffer_data[] = {
    {-1, 1, 0.0},
    {1, 1, 0.0},
    {1, -1, 0.0},
    {-1, -1, 0.0},
};

static GLushort index_buffer_data[] = {
    0, 1, 2, 0, 2, 3
};

static GLKVector2 texture_buffer_data_r0[] = {
    {0.0, 0.0},
    {1.0, 0.0},
    {1.0, 1.0},
    {0.0, 1.0},
};

static GLKVector2 texture_buffer_data_r90[] = {
    {0.0, 1.0},
    {0.0, 0.0},
    {1.0, 0.0},
    {1.0, 1.0},
};

static GLKVector2 texture_buffer_data_r180[] = {
    {1.0, 1.0},
    {0.0, 1.0},
    {0.0, 0.0},
    {1.0, 0.0},
};

static GLKVector2 texture_buffer_data_r270[] = {
    {1.0, 0.0},
    {1.0, 1.0},
    {0.0, 1.0},
    {0.0, 0.0},
};

static GLuint vertex_buffer_id = 0;
static GLuint index_buffer_id = 0;
static GLuint texture_buffer_id = 0;

static int const index_count = 6;
static int const vertex_count = 4;


@implementation SYPlayerGLNormalModel

void setup_normal()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        glGenBuffers(1, &index_buffer_id);
        glGenBuffers(1, &vertex_buffer_id);
        glGenBuffers(1, &texture_buffer_id);
    });
}

- (void)setupModel
{
    setup_normal();
    self.index_count = index_count;
    self.vertex_count = vertex_count;
    self.index_id = index_buffer_id;
    self.vertex_id = vertex_buffer_id;
    self.texture_id = texture_buffer_id;
}

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
{
    [self bindPositionLocation:position_location
          textureCoordLocation:textureCoordLocation
             textureRotateType:SYPlayerGLModelTextureRotateType0];
}

- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(SYPlayerGLModelTextureRotateType)textureRotateType
{
    // index
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.index_count * sizeof(GLushort), index_buffer_data, GL_STATIC_DRAW);
    
    // vertex
    glBindBuffer(GL_ARRAY_BUFFER, self.vertex_id);
    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 3 * sizeof(GLfloat), vertex_buffer_data, GL_STATIC_DRAW);
    glEnableVertexAttribArray(position_location);
    glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
    
    // texture coord
    glBindBuffer(GL_ARRAY_BUFFER, self.texture_id);
    switch (textureRotateType) {
        case SYPlayerGLModelTextureRotateType0:
            glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), texture_buffer_data_r0, GL_DYNAMIC_DRAW);
            break;
        case SYPlayerGLModelTextureRotateType90:
            glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), texture_buffer_data_r90, GL_DYNAMIC_DRAW);
            break;
        case SYPlayerGLModelTextureRotateType180:
            glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), texture_buffer_data_r180, GL_DYNAMIC_DRAW);
            break;
        case SYPlayerGLModelTextureRotateType270:
            glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), texture_buffer_data_r270, GL_DYNAMIC_DRAW);
            break;
    }
    glEnableVertexAttribArray(textureCoordLocation);
    glVertexAttribPointer(textureCoordLocation, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}

@end
