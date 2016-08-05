//
//  YYGIF.h
//  VideoToGif
//
//  Created by 胡阳阳 on 16/8/4.
//  Copyright © 2016年 胡阳阳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <CoreServices/CoreServices.h>
#import <WebKit/WebKit.h>
#endif
@interface YYGIF : NSObject
/**
 *  将本地视频转换成Gif图
 *
 *  @param videoURL          本地视频的url 使用系统+ (NSURL *)fileURLWithPath:(NSString *)path;将本地path转url
 *  @param frameCount        一共切多少张
 *  @param delayTime         每一张几秒钟显示
 *  @param loopCount         是否循环
 *  @param isNeedCompression 是否需要压缩
 *  @param compressionWidth  压缩尺寸 宽
 *  @param compressionHigth  压缩尺寸 高
 *  @param filleName         生成gif 的文件名
 *  @param completionBlock   成功回调 会返回 gif tmp文件下本地路径
 */
+ (void)createGIFfromURL:(NSURL*)videoURL withFrameCount:(int)frameCount delayTime:(float)delayTime loopCount:(int)loopCount needCompression:(BOOL)isNeedCompression andCompressionWidth:(float)compressionWidth andCompressionHight:(float)compressionHigth andFileName:(NSString*)filleName completion:(void(^)(NSString *GifPath))completionBlock;
@end
