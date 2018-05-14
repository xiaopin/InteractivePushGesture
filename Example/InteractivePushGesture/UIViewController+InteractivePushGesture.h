//
//  UIViewController+InteractivePushGesture.h
//  https://github.com/xiaopin/InteractivePushGesture.git
//
//  Created by nhope on 2018/5/14.
//  Copyright © 2018年 xiaopin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIViewControllerInteractivePushGestureDelegate;


/// 给控制器增加一个左滑push的手势功能
@interface UIViewController (InteractivePushGesture)

/// 是否启用左滑push手势, 默认 `NO`
@property (nonatomic, assign, getter=isInteractivePushGestureEnabled) IBInspectable BOOL interactivePushGestureEnabled NS_AVAILABLE_IOS(8_0);
/// 代理
@property (nonatomic, weak) IBOutlet id<UIViewControllerInteractivePushGestureDelegate> interactivePushGestureDelegate NS_AVAILABLE_IOS(8_0);

@end


@protocol UIViewControllerInteractivePushGestureDelegate <NSObject>

@required
/**
 返回需要被push的新控制器

 @param fromViewController 当前控制器(执行push操作的控制器)
 @return 被push的控制器
 */
- (UIViewController *)destinationViewControllerFromViewController:(UIViewController *)fromViewController;

@end
