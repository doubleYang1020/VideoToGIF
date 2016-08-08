//
//  ViewController.m
//  VideoToGIFDemo
//
//  Created by 胡阳阳 on 16/8/4.
//  Copyright © 2016年 胡阳阳. All rights reserved.
//

#import "ViewController.h"
#import "YYGIF.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+GIF.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
@interface ViewController ()
@property (nonatomic ,strong) MBProgressHUD *HUD;
@property (nonatomic ,strong) UIImageView* gifImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self getFIG];
    
    _gifImageView = [[UIImageView alloc] init];
    _gifImageView.backgroundColor = UIColor.grayColor;
    [self.view addSubview:_gifImageView];
    UIView* superView = self.view;
    [_gifImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@(180));
        make.center.equalTo(superView);
    }];
    
    _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    /*
    /// UIActivityIndicatorView.
    MBProgressHUDModeIndeterminate,  转菊花
    /// A round, pie-chart like, progress view.
    MBProgressHUDModeDeterminate,
    /// Horizontal progress bar.
    MBProgressHUDModeDeterminateHorizontalBar,
    /// Ring-shaped progress view.
    MBProgressHUDModeAnnularDeterminate,
    /// Shows a custom view.
    MBProgressHUDModeCustomView,
    /// Shows only labels.
    MBProgressHUDModeText
     */

    _HUD.mode = MBProgressHUDModeIndeterminate;
    _HUD.label.text = @"loding";
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)getFIG
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    //demo 中video.mp4 为18s 视频 希望gif 帧数位8， 所以 FrameCount ＝ 18 ＊ 8 ; delayTime ＝ 1/8;
    
    [YYGIF createGIFfromURL:videoURL withFrameCount:144 delayTime:0.125 loopCount:0 needCompression:YES andCompressionWidth:180 andCompressionHight:180 andFileName:@"测试.gif" completion:^(NSString *GifPath) {
        NSLog(@"Finished generating GIF: %@", GifPath);
        
        if (GifPath)
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _HUD.label.text = @"Complete！";
                [_HUD hideAnimated:1 afterDelay:1];
                NSData* gifData = [NSData dataWithContentsOfFile:GifPath];
                _gifImageView.image = [UIImage sd_animatedGIFWithData:gifData];

                NSLog(@"");
            });
            
            
            
            
        }else
        {
            
        }
        
    }];
    
}

@end
