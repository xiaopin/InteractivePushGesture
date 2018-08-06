//
//  UIViewController+InteractivePushGesture.m
//  https://github.com/xiaopin/InteractivePushGesture.git
//
//  Created by nhope on 2018/5/14.
//  Copyright © 2018年 xiaopin. All rights reserved.
//

#import "UIViewController+InteractivePushGesture.h"
#import <objc/message.h>

#pragma mark - 动画执行者

@interface XPInteractivePushAnimatedTransitioning: NSObject <UIViewControllerAnimatedTransitioning>

@end

@implementation XPInteractivePushAnimatedTransitioning

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    if (toView) {
        [transitionContext.containerView addSubview:toView];
    }
    
    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    toView.frame = CGRectOffset(finalFrame, finalFrame.size.width, 0.0);
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
        toView.frame = finalFrame;
    } completion:^(BOOL finished) {
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        [transitionContext completeTransition:!wasCancelled];
    }];
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 1.0;
}

@end

#pragma mark - 导航栏控制器代理

@interface XPNavigationControllerDelegateObject: NSObject <UINavigationControllerDelegate>

@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;

@end

@implementation XPNavigationControllerDelegateObject

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([animationController isKindOfClass:[XPInteractivePushAnimatedTransitioning class]]) {
        return self.interactiveTransition;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    if (operation == UINavigationControllerOperationPush) {
        return [[XPInteractivePushAnimatedTransitioning alloc] init];
    }
    return nil;
}

@end

#pragma mark - 手势代理

@interface XPPushGestureRecognizerDelegateObject: NSObject <UIGestureRecognizerDelegate>
{
    __weak UIPanGestureRecognizer *_gestureRecognizer;
}
- (instancetype)initWithGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer;

@end

@implementation XPPushGestureRecognizerDelegateObject

- (instancetype)initWithGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer {
    self = [[XPPushGestureRecognizerDelegateObject alloc] init];
    if (self) {
        _gestureRecognizer = gestureRecognizer;
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _gestureRecognizer) {
        CGPoint const velocity = [_gestureRecognizer velocityInView:gestureRecognizer.view];
        BOOL isHorizontal = fabs(velocity.x) > fabs(velocity.y); // 水平滑动（|x|<|y|则为垂直方向滑动）
        return (isHorizontal && velocity.x < -30.0 && velocity.y >= 0.0);
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return (gestureRecognizer == _gestureRecognizer);
}

@end

#pragma mark -

static const char kXPNavigationControllerDelegateObjectKey = '\0';

@implementation UIViewController (InteractivePushGesture)

#pragma mark Actions

- (void)handleInteractivePushGesture:(UIPanGestureRecognizer *)sender {
    XPNavigationControllerDelegateObject *delegate = objc_getAssociatedObject(self, &kXPNavigationControllerDelegateObjectKey);
    CGPoint translation = [sender translationInView:self.view];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSParameterAssert(self.interactivePushGestureDelegate);
            NSParameterAssert(self.navigationController);
            if (![self isInteractivePushGestureEnabled]) {
                return;
            }
            delegate = [[XPNavigationControllerDelegateObject alloc] init];
            delegate.interactiveTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
            self.navigationController.delegate = delegate;
            objc_setAssociatedObject(self, &kXPNavigationControllerDelegateObjectKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            UIViewController *destinationViewController = [self.interactivePushGestureDelegate destinationViewControllerFromViewController:self];
            NSAssert(destinationViewController && [destinationViewController isKindOfClass:UIViewController.class],
                     @"`-destinationViewControllerFromViewController:` can not be nil and must be UIViewController or its subclass.");
            [self.navigationController pushViewController:destinationViewController animated:YES];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (CGPointEqualToPoint(translation, CGPointZero)) {
                return;
            }
            CGFloat percent = fabs(translation.x) / CGRectGetWidth(self.view.frame);
            [delegate.interactiveTransition updateInteractiveTransition:percent];
            break;
        }
        default: {
            if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
                CGFloat percent = fabs(translation.x) / CGRectGetWidth(self.view.frame);
                if (percent >= 0.3) {
                    [delegate.interactiveTransition finishInteractiveTransition];
                } else {
                    [delegate.interactiveTransition cancelInteractiveTransition];
                    
                }
            }
            // 重新启用原生pop手势并及时释放代理对象
            self.navigationController.delegate = nil;
            objc_setAssociatedObject(self, &kXPNavigationControllerDelegateObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            break;
        }
    }
}

#pragma mark setter & getter

static char const kXPPushGestureRecognizerDelegateObjectKey = '\0';

- (void)setInteractivePushGestureEnabled:(BOOL)enabled {
    objc_setAssociatedObject(self, @selector(isInteractivePushGestureEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (enabled) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleInteractivePushGesture:)];
        panGesture.delaysTouchesBegan = YES;
        [self.view addGestureRecognizer:panGesture];
        
        XPPushGestureRecognizerDelegateObject *delegate = [[XPPushGestureRecognizerDelegateObject alloc] initWithGestureRecognizer:panGesture];
        panGesture.delegate = delegate;
        panGesture.delaysTouchesBegan = YES;
        objc_setAssociatedObject(self, &kXPPushGestureRecognizerDelegateObjectKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        SEL sel = @selector(handleInteractivePushGesture:);
        for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
            if (![gesture isKindOfClass:[UIPanGestureRecognizer class]]) continue;
            NSArray *targets = [gesture valueForKey:@"targets"];
            id target = targets.firstObject;
            if ([target valueForKey:@"target"] == self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                SEL action = (__bridge void *)[target performSelector:NSSelectorFromString(@"action")];
#pragma clang diagnostic pop
                if (action == sel) {
                    gesture.enabled = NO;
                    [self.view removeGestureRecognizer:gesture];
                    break;
                }
            }
        }
        objc_setAssociatedObject(self, &kXPPushGestureRecognizerDelegateObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (BOOL)isInteractivePushGestureEnabled {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setInteractivePushGestureDelegate:(id<UIViewControllerInteractivePushGestureDelegate>)delegate {
    objc_setAssociatedObject(self, @selector(interactivePushGestureDelegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<UIViewControllerInteractivePushGestureDelegate>)interactivePushGestureDelegate {
    return objc_getAssociatedObject(self, _cmd);
}

@end

