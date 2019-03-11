//
//  ViewController.m
//  RunTimeLearn
//
//  Created by sunchunlei on 2019/3/9.
//  Copyright © 2019 zhujun. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>

#import "subTestObject.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    
}

- (void)getMethodName {
    // 创建C函数指针 用来接收IMP
    void(*function)(id,SEL,NSObject*);
    
    function = (void(*)(id, SEL, NSObject*)) [self methodForSelector:@selector(readView:)];
    
    function(self,@selector(readView:),UIColor.redColor);
}
- (void)readView:(UIColor *)color{
    self.view.backgroundColor = [UIColor redColor];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
   
//     [self getMethodName];

    // IMP 的 Block 实现
    subTestObject *testOB = [[subTestObject alloc] init];
    [testOB changeTestMethod];
}











@end
