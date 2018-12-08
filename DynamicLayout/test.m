//
//  test.m
//  DynamicLayout
//
//  Created by LyinTech on 2018/12/8.
//  Copyright © 2018 LyinTech. All rights reserved.
//

#import "test.h"
#import "DynamicLayout-Swift.h"

@implementation test

- (void)test {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"json" ofType:@"json"];
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@, %@", string.locationFormatedString, string.locationCoordinateIfExist);
}


@end
