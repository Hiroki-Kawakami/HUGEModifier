//
//  HMWorkspace.m
//  HUGEModifier
//
//  Created by hiroki on 2020/09/29.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import "HMWorkspace.h"
#import "HMProfile.h"
#import "HMCadProfile.h"

@implementation HMWorkspace {
    NSWorkspace *workspace;
    NSDictionary<NSString*, HMProfile*> *profiles;
}

static HMWorkspace *_shared = nil;

+ (HMWorkspace *)shared {
    if (!_shared) _shared = [HMWorkspace new];
    return _shared;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        profiles = @{
            @"default": [HMProfile new],
            @"cad": [HMCadProfile new]
        };
        
        workspace = [NSWorkspace sharedWorkspace];
        [[workspace notificationCenter] addObserver:self selector:@selector(updateProfile) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    }
    return self;
}

- (void)setManager:(HMManager *)manager {
    _manager = manager;
    [self updateProfile];
}

- (void)updateProfile {
    NSRunningApplication *frontmostApplication = [workspace frontmostApplication];
    if ([frontmostApplication.bundleURL.lastPathComponent isEqualToString:@"FreeCAD.app"]) {
        [_manager setCurrentProfile:profiles[@"cad"]];
    } else {
        [_manager setCurrentProfile:profiles[@"default"]];
    }
}

@end
