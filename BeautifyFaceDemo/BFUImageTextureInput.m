//
//  BFUImageTextureInput.m
//  BeautifyFaceDemo
//
//  Created by 聚智在线 on 2018/4/28.
//  Copyright © 2018年 guikz. All rights reserved.
//

#import "BFUImageTextureInput.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface BFUImageTextureInput ()
{
    GPUImageFramebuffer *_newInputFramebuffer;
}
@property(nonatomic,strong)NSMutableArray* bufferArray;
@end

@implementation BFUImageTextureInput

-(NSMutableArray*)bufferArray{
    if (!_bufferArray) {
        _bufferArray = [NSMutableArray array];
    }
    return _bufferArray;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    [self.bufferArray addObject:_newInputFramebuffer];
}

// TODO: Deal with the fact that the texture changes regularly as a result of the caching
- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex
{
    _newInputFramebuffer = newInputFramebuffer;
    [super setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
//    [self.bufferArray addObject:newInputFramebuffer];
}


-(void)creatGif{
    NSMutableArray* imgArray = [NSMutableArray array];
    for (GPUImageFramebuffer* buffer in self.bufferArray) {
        //TODO 图片需要压缩
        CGImageRef image = [buffer newCGImageFromFramebufferContents];
        UIImage* uiimageF = [UIImage imageWithCGImage:image];
        [imgArray addObject:uiimageF];
    }
    [self creatGifWithImageArray:imgArray];
}
-(void)creatGifWithImageArray:(NSArray*)images{
    // TODO 耗时操作  需要后台处理
    //创建爱你gif文件
    NSArray *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *doucmentStr =[document objectAtIndex:0];
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSString *textDic = [doucmentStr stringByAppendingString:@"/gif"];
    [filemanager createDirectoryAtPath:textDic withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [textDic stringByAppendingString:@"test1.gif"];
    NSLog(@"-----%@",path);
    //配置gif属性
    CGImageDestinationRef destion;
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, false);
    destion = CGImageDestinationCreateWithURL(url, kUTTypeGIF, images.count, NULL);
    NSDictionary *frameDic = [NSDictionary dictionaryWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.3],(NSString*)kCGImagePropertyGIFDelayTime, nil] forKey:(NSString*)kCGImagePropertyGIFDelayTime];
    
    NSMutableDictionary *gifParmdict = [NSMutableDictionary dictionaryWithCapacity:2];
    [gifParmdict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCGImagePropertyGIFHasGlobalColorMap];
    [gifParmdict setObject:(NSString*)kCGImagePropertyColorModelRGB forKey:(NSString*)kCGImagePropertyColorModel];
    [gifParmdict setObject:[NSNumber numberWithInt:8] forKey:(NSString*)kCGImagePropertyDepth];
    [gifParmdict setObject:[NSNumber numberWithInt:0] forKey:(NSString*)kCGImagePropertyGIFLoopCount];
    NSDictionary *gifProperty = [NSDictionary dictionaryWithObject:gifParmdict forKey:(NSString*)kCGImagePropertyGIFDictionary];
    
    for (UIImage *dimage in images) {
        CGImageDestinationAddImage(destion, dimage.CGImage, (__bridge CFDictionaryRef)frameDic);
    }
    
    CGImageDestinationSetProperties(destion,(__bridge CFDictionaryRef)gifProperty);
    CGImageDestinationFinalize(destion);
    CFRelease(destion);
    
}
@end
