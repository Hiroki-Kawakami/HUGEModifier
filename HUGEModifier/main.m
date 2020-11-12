//
//  main.m
//  HUGEModifier
//
//  Created by hiroki on 2020/09/17.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMManager.h"
#import "HMWorkspace.h"
#import "HMProfile.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        [[HMManager sharedManager] open];
        [[HMWorkspace shared] setManager:[HMManager sharedManager]];
        CFRunLoopRun();
    }
    return 0;
}
