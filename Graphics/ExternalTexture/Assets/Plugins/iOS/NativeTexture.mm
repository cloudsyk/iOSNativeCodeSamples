
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

#include "UnityMetalSupport.h"

#include <stdlib.h>
#include <stdint.h>

static UIImage* LoadImage(const char* filename)
{
    NSString* imageName = [NSString stringWithUTF8String:filename];
    NSString* imagePath = [[[[NSBundle mainBundle] pathForResource: imageName ofType: @"png"] retain] autorelease];

    return [[UIImage imageWithContentsOfFile: imagePath] retain];
}

// you need to free this pointer
static void* LoadDataFromImage(UIImage* image)
{
    CGImageRef imageData    = image.CGImage;
    unsigned   imageW       = CGImageGetWidth(imageData);
    unsigned   imageH       = CGImageGetHeight(imageData);

    // for the sake of the sample we enforce 128x128 textures
    assert(imageW == 128 && imageH == 128);

    void* textureData = ::malloc(imageW*imageH * 4);
    ::memset(textureData, 0x00, imageW*imageH * 4);

    CGContextRef textureContext = CGBitmapContextCreate(textureData, imageW, imageH, 8, imageW * 4, CGImageGetColorSpace(imageData), kCGImageAlphaPremultipliedLast);
    CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
    CGContextDrawImage(textureContext, CGRectMake(0,0, imageW, imageH), imageData);
    CGContextRelease(textureContext);

    return textureData;
}

static uintptr_t CreateGlesTexture(void* data, unsigned w, unsigned h)
{
    GLuint texture = 0;
    glGenTextures(1, &texture);

    GLint curGLTex = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &curGLTex);

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

    glBindTexture(GL_TEXTURE_2D, curGLTex);

    return texture;
}
static void DestroyGlesTexture(uintptr_t tex)
{
    GLint curGLTex = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &curGLTex);

    GLuint glTex = tex;
    glDeleteTextures(1, &glTex);

    glBindTexture(GL_TEXTURE_2D, curGLTex);
}


static uintptr_t CreateMetalTexture(void* data, unsigned w, unsigned h)
{
#if defined(__IPHONE_8_0) && !TARGET_IPHONE_SIMULATOR
    Class MTLTextureDescriptorClass = [UnityGetMetalBundle() classNamed:@"MTLTextureDescriptor"];

    MTLTextureDescriptor* texDesc =
        [MTLTextureDescriptorClass texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:w height:h mipmapped:NO];

    id<MTLTexture> tex = [UnityGetMetalDevice() newTextureWithDescriptor:texDesc];

    MTLRegion r = MTLRegionMake3D(0,0,0, w,h,1);
    [tex replaceRegion:r mipmapLevel:0 withBytes:data bytesPerRow:w*4];

    return (uintptr_t)(__bridge_retained void*)tex;
#else
    return 0;
#endif
}
static void DestroyMetalTexture(uintptr_t tex)
{
    id<MTLTexture> mtltex = (__bridge_transfer id<MTLTexture>)(void*)tex;
    mtltex = nil;
}



extern "C" intptr_t CreateNativeTexture(const char* filename)
{
    UIImage*    image       = LoadImage(filename);
    void*       textureData = LoadDataFromImage(image);

    uintptr_t ret = 0;
    if(UnitySelectedRenderingAPI() == apiMetal)
        ret = CreateMetalTexture(textureData, image.size.width, image.size.height);
    else
        ret = CreateGlesTexture(textureData, image.size.width, image.size.height);

    ::free(textureData);
    [image release];

    return ret;
}

extern "C" void DestroyNativeTexture(uintptr_t tex)
{
    if(UnitySelectedRenderingAPI() == apiMetal)
        DestroyMetalTexture(tex);
    else
        DestroyGlesTexture(tex);
}
