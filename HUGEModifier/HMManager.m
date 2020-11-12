//
//  HMManager.m
//  HUGEModifier
//
//  Created by hiroki on 2020/09/17.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import "HMManager.h"
#import <IOKit/hid/IOHIDManager.h>
#import "HMVirtualHID.h"
#import "HMProfile.h"

@implementation HMManager {
    IOHIDManagerRef hidManager;
    u_int8_t currentButtons;
}

static HMManager *_sharedManager = nil;

+ (HMManager *)sharedManager {
    if (!_sharedManager) _sharedManager = [HMManager new];
    return _sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDManagerOptionNone);
        currentButtons = 0;
        [self setCurrentProfile:[HMProfile new]];
    }
    return self;
}

- (void)open {
    NSDictionary *matching = @{
        @kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
        @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_Mouse),
        @kIOHIDVendorIDKey: @(0x056e),
        @kIOHIDProductIDKey: @(0x010d),
    };
    IOHIDManagerSetDeviceMatching(hidManager, (CFDictionaryRef)matching);
    IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOReturn ret = IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeSeizeDevice);
    if (ret == kIOReturnSuccess) {
        IOHIDManagerRegisterInputReportCallback(hidManager, &HMManager_handleReport, (__bridge void * _Nullable)(self));
    } else {
        fprintf(stderr, "Failed to open\n");
    }
}


struct HMMouseReport {
    uint8_t tag;
    uint8_t buttons;
    int16_t x;
    int16_t y;
    int8_t vertical;
    int8_t horizontal;
};

- (void)handleReport:(struct HMMouseReport *)report {
    // check clicked
    uint8_t buttonsXOR = currentButtons ^ report->buttons;
    for (uint8_t i = 0; i < 8; i++) {
        if (buttonsXOR >> i & 1) [_currentProfile clicked:i isDown:report->buttons >> i & 1 manager:self];
    }
    currentButtons = report->buttons;
    
    // check mouse move
    if (report->x || report->y) [_currentProfile movedX:report->x Y:report->y manager:self];
    
    // check wheel move
    if (report->vertical) [_currentProfile wheelVertical:report->vertical manager:self];
    if (report->horizontal) [_currentProfile wheelHorizontal:report->horizontal manager:self];
}

void HMManager_handleReport(void* context, IOReturn result, void* sender, IOHIDReportType type, UInt32 reportID, u_int8_t* report, CFIndex reportLength) {
    HMManager *targetManager = (__bridge HMManager *)(context);
    [targetManager handleReport:(struct HMMouseReport *)report];
}

- (BOOL)isMouseDown:(uint8_t)button {
    return currentButtons >> button & 1;
}

- (void)setCurrentProfile:(HMProfile *)currentProfile {
    _currentProfile = currentProfile;
}

@end
