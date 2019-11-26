//
//  VideoListController.h
//  ZYPlayer-OC
//
//  Created by 嘴爷 on 2019/11/26.
//  Copyright © 2019 嘴爷. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VideoListController;
@protocol VideoListControllerDelegate<NSObject>
@optional
-(void)videoListController:(VideoListController*)videoController selectInfo:(NSDictionary*)info;

@end

@interface VideoListController : UIViewController

/** <#description#> */
@property (nonatomic, weak) id<VideoListControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
