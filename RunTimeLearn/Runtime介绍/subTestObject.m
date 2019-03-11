//
//  subTestObject.m
//  RunTimeLearn
//
//  Created by sunchunlei on 2019/3/11.
//  Copyright © 2019 zhujun. All rights reserved.
//

#import "subTestObject.h"

#import <objc/runtime.h>
#import <objc/message.h>

@implementation subTestObject


- (void)changeTestMethod {
    IMP function = imp_implementationWithBlock(^(id self,NSString *text){
         NSLog(@"%@",text);
    });
    const char *types = sel_getName(@selector(testMethod:));
    class_replaceMethod([subTestObject class],@selector(testMethod:),function,types);
    [self testMethod:@"hahahh"];
}

@end
