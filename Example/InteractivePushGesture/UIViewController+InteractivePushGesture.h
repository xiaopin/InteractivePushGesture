//
//  UIViewController+InteractivePushGesture.h
//  https://github.com/xiaopin/InteractivePushGesture.git
//
//  Created by nhope on 2018/5/14.
//  Copyright © 2018年 xiaopin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIViewControllerInteractivePushGestureDelegate;


@interface UIViewController (InteractivePushGesture)

/// default `NO`
@property (nonatomic, assign, getter=isInteractivePushGestureEnabled) IBInspectable BOOL interactivePushGestureEnabled;
@property (nonatomic, weak) id<UIViewControllerInteractivePushGestureDelegate> interactivePushGestureDelegate;

@end


@protocol UIViewControllerInteractivePushGestureDelegate <NSObject>

@required
- (UIViewController *)destinationViewControllerFromViewController:(UIViewController *)fromViewController;

@end
