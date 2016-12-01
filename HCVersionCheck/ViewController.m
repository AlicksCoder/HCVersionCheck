//
//  ViewController.m
//  HCVersionCheck
//
//  Created by Alicks zhu on 2016/12/1.
//  Copyright © 2016年 HC. All rights reserved.
//

#import "ViewController.h"
#import "HCVersionCheck.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 每启动 3次 检查一次更新
//    [HCVersionCheck checkWithOpenTimes:3];
    
    //每2天 检查一次更新
//    [HCVersionCheck checkWithDays:2];
    
    
    
    [HCVersionCheck checkWithOpenTimes:1 allowIgnore:YES];
    
    // 开启强制更新
//    [HCVersionCheck ForceUpdate:NO];
    

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
