//
//  ViewController.m
//  Example
//
//  Created by nhope on 2018/5/14.
//  Copyright © 2018年 xiaopin. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+InteractivePushGesture.h"

@interface ViewController ()<UIViewControllerInteractivePushGestureDelegate>

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.interactivePushGestureEnabled = YES;
    self.interactivePushGestureDelegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - <UIViewControllerInteractivePushGestureDelegate>

- (UIViewController *)destinationViewControllerFromViewController:(UIViewController *)fromViewController {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0];
    return vc;
}


@end
