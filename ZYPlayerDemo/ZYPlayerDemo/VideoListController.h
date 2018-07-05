//
//  VideoListController.h
//  ZYPlayerDemo
//
//  Created by 嘴爷 on 2018/7/5.
//  Copyright © 2018年 嘴爷. All rights reserved.
//

#import <UIKit/UIKit.h>
@class VideoListController;
@protocol VideoListControllerDelegate<NSObject>
@optional
-(void)videoListController:(VideoListController*)videoController selectInfo:(NSDictionary*)info;

@end

@interface VideoListController : UIViewController

/** <#description#> */
@property (nonatomic, weak) id<VideoListControllerDelegate> delegate;

@end
