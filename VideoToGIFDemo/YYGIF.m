//
//  YYGIF.m
//  VideoToGif
//
//  Created by 胡阳阳 on 16/8/4.
//  Copyright © 2016年 胡阳阳. All rights reserved.
//

#import "YYGIF.h"
#define timeInterval @(600)
#define tolerance    @(0.01)

typedef NS_ENUM(NSInteger, GIFSize) {
    GIFSizeVeryLow  = 2,
    GIFSizeLow      = 3,
    GIFSizeMedium   = 5,
    GIFSizeHigh     = 7,
    GIFSizeOriginal = 10
};
@implementation YYGIF


+ (void)createGIFfromURL:(NSURL*)videoURL withFrameCount:(int)frameCount delayTime:(float)delayTime loopCount:(int)loopCount needCompression:(BOOL)isNeedCompression andCompressionWidth:(float)compressionWidth andCompressionHight:(float)compressionHigth andFileName:(NSString*)filleName completion:(void(^)(NSString *GifPath))completionBlock {
    
    // Convert the video at the given URL to a GIF, and return the GIF's URL if it was created.
    // The frames are spaced evenly over the video, and each has the same duration.
    // delayTime is the amount of time for each frame in the GIF.
    // loopCount is the number of times the GIF will repeat. Defaults to 0, which means repeat infinitely.
    
    // Create properties dictionaries
    NSLog(@"取出时间戳");
    NSDictionary *fileProperties = [self filePropertiesWithLoopCount:loopCount];
    NSDictionary *frameProperties = [self framePropertiesWithDelayTime:delayTime];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    
    // Get the length of the video in seconds
    float videoLength = (float)asset.duration.value/asset.duration.timescale;
    
    // How far along the video track we want to move, in seconds.
    float increment = (float)videoLength/frameCount;
    
    // Add frames to the buffer
    NSMutableArray *timePoints = [NSMutableArray array];
    for (int currentFrame = 0; currentFrame<frameCount; ++currentFrame) {
        float seconds = (float)increment * currentFrame;
        CMTime time = CMTimeMakeWithSeconds(seconds, [timeInterval intValue]);
        [timePoints addObject:[NSValue valueWithCMTime:time]];
    }
    
    // Prepare group for firing completion block
    dispatch_group_t gifQueue = dispatch_group_create();
    dispatch_group_enter(gifQueue);
    
    __block NSString *gifPath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"取出时间戳 动作完成 －> 取出CGImageRef");
        gifPath = [self createGIFforTimePoints:timePoints fromURL:videoURL fileProperties:fileProperties frameProperties:frameProperties frameCount:frameCount gifSize:GIFSizeMedium needCompression:isNeedCompression andCompressionWidth:compressionWidth andCompressionHight:compressionHigth andFileName:filleName];
        
        dispatch_group_leave(gifQueue);
    });
    
    dispatch_group_notify(gifQueue, dispatch_get_main_queue(), ^{
        // Return GIF URL
        completionBlock(gifPath);
    });
    
}

#pragma mark - Base methods

+ (NSString *)createGIFforTimePoints:(NSArray *)timePoints fromURL:(NSURL *)url fileProperties:(NSDictionary *)fileProperties frameProperties:(NSDictionary *)frameProperties frameCount:(int)frameCount gifSize:(GIFSize)gifSize needCompression:(BOOL)isNeedCompression andCompressionWidth:(float)compressionWidth andCompressionHight:(float)compressionHigth andFileName:(NSString*)filleName{
    
    NSString *temporaryFile = [NSTemporaryDirectory() stringByAppendingString:filleName];
    NSURL *fileURL = [NSURL fileURLWithPath:temporaryFile];
    if (fileURL == nil)
        return nil;
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF , frameCount, NULL);
    
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime tol = CMTimeMakeWithSeconds([tolerance floatValue], [timeInterval intValue]);
    generator.requestedTimeToleranceBefore = tol;
    generator.requestedTimeToleranceAfter = tol;
    
    NSError *error = nil;
    CGImageRef previousImageRefCopy = nil;
    for (NSValue *time in timePoints) {
        CGImageRef imageRef;
        
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        imageRef = (float)gifSize/10 != 1 ? createImageWithScale([generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error], (float)gifSize/10) : [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
#elif TARGET_OS_MAC
        imageRef = [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
#endif
        
        if (error) {
            NSLog(@"Error copying image: %@", error);
        }
        if (imageRef) {
            CGImageRelease(previousImageRefCopy);
            previousImageRefCopy = CGImageCreateCopy(imageRef);
        } else if (previousImageRefCopy) {
            imageRef = CGImageCreateCopy(previousImageRefCopy);
        } else {
            NSLog(@"Error copying image and no previous frames to duplicate");
            return nil;
        }
        if (isNeedCompression) {
            UIImage* image = [UIImage imageWithCGImage:imageRef];
            //        NSData* data = UIImageJPEGRepresentation(image, 1);
            //        UIImage* newImage = [UIImage imageWithData:data];
            
            CGSize targetSize = CGSizeMake(compressionWidth, compressionHigth);
            UIImage *sourceImage = image;
            UIImage *newImage = nil;
            CGSize imageSize = sourceImage.size;
            CGFloat width = imageSize.width;
            CGFloat height = imageSize.height;
            CGFloat targetWidth = targetSize.width;
            CGFloat targetHeight = targetSize.height;
            CGFloat scaleFactor = 0.0;
            CGFloat scaledWidth = targetWidth;
            CGFloat scaledHeight = targetHeight;
            CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
            
            if (CGSizeEqualToSize(imageSize, targetSize) == NO)
            {
                
                CGFloat widthFactor = targetWidth / width;
                CGFloat heightFactor = targetHeight / height;
                
                if (widthFactor > heightFactor)
                    scaleFactor = widthFactor; // scale to fit height
                else
                    scaleFactor = heightFactor; // scale to fit width
                scaledWidth= width * scaleFactor;
                scaledHeight = height * scaleFactor;
                
                // center the image
                if (widthFactor > heightFactor)
                {
                    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
                }
                else if (widthFactor < heightFactor)
                {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                }
            }
            
            UIGraphicsBeginImageContext(targetSize); // this will crop
            
            CGRect thumbnailRect = CGRectZero;
            thumbnailRect.origin = thumbnailPoint;
            thumbnailRect.size.width= scaledWidth;
            thumbnailRect.size.height = scaledHeight;
            
            [sourceImage drawInRect:thumbnailRect];
            
            newImage = UIGraphicsGetImageFromCurrentImageContext();
            if(newImage == nil)
                NSLog(@"could not scale image");
            
            //pop the context to get back to the default
            UIGraphicsEndImageContext();
            
            CGImageRef imageRef1 = newImage.CGImage;
            NSLog(@"开始add,%@",time);
            CGImageDestinationAddImage(destination, imageRef1, (CFDictionaryRef)frameProperties);
            NSLog(@"当此add完成,%@",time);
        }else
        {
            CGImageDestinationAddImage(destination, imageRef, (CFDictionaryRef)frameProperties);
        }
        
        
        
        CGImageRelease(imageRef);
    }
    CGImageRelease(previousImageRefCopy);
    NSLog(@"取出imageRef完成");
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)fileProperties);
    // Finalize the GIF
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to finalize GIF destination: %@", error);
        if (destination != nil) {
            CFRelease(destination);
        }
        return nil;
    }
    CFRelease(destination);
    
    return temporaryFile;
}


#pragma mark - Helpers

CGImageRef createImageWithScale(CGImageRef imageRef, float scale) {
    
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    CGSize newSize = CGSizeMake(CGImageGetWidth(imageRef)*scale, CGImageGetHeight(imageRef)*scale);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    //Release old image
    CFRelease(imageRef);
    // Get the resized image from the context and a UIImage
    imageRef = CGBitmapContextCreateImage(context);
    
    UIGraphicsEndImageContext();
#endif
    
    return imageRef;
}

#pragma mark - Properties

+ (NSDictionary *)filePropertiesWithLoopCount:(int)loopCount {
    return @{(NSString *)kCGImagePropertyGIFDictionary:
                 @{(NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)}
             };
}

+ (NSDictionary *)framePropertiesWithDelayTime:(float)delayTime {
    
    return @{(NSString *)kCGImagePropertyGIFDictionary:
                 @{(NSString *)kCGImagePropertyGIFDelayTime: @(delayTime)},
             (NSString *)kCGImagePropertyColorModel:(NSString *)kCGImagePropertyColorModelRGB
             };
}


@end
