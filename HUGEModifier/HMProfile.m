//
//  HMProfile.m
//  HUGEModifier
//
//  Created by hiroki on 2020/09/29.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import "HMProfile.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import "HMManager.h"

@implementation HMProfile

- (instancetype)init
{
    if (self = [super init]) {
        virtualHID = [HMVirtualHID shared];
    }
    return self;
}

- (void)clicked:(uint8_t)button isDown:(BOOL)down manager:(HMManager*)manager {
    
    if (button == 6) {
        [virtualHID button:0 down:down];
    } else if (button == 7) {
        [virtualHID button:1 down:down];
    } else if (button == 0) {
        if (!down) return;
        uint8_t code = kHIDUsage_KeyboardReturnOrEnter;
        if ([manager isMouseDown:1]) code = kHIDUsage_KeyboardSpacebar;
        [virtualHID key:code down:YES];
        [virtualHID key:code down:NO];
    } else if (button == 5) {
        if (!down) return;
        uint8_t code = kHIDUsage_KeyboardOpenBracket;
        if ([manager isMouseDown:1]) code = kHIDUsage_KeyboardCloseBracket;
        [virtualHID command:YES];
        [virtualHID key:code down:YES];
        [virtualHID command:NO];
        [virtualHID key:code down:NO];
    } else if (button == 4) { // Mission Control
        if (!down) return;
        [virtualHID control:YES];
        [virtualHID key:kHIDUsage_KeyboardUpArrow down:YES];
        [virtualHID control:NO];
        [virtualHID key:kHIDUsage_KeyboardUpArrow down:NO];
    } else if (button == 3) { // Expose
        if (!down) return;
        [virtualHID control:YES];
        [virtualHID key:kHIDUsage_KeyboardDownArrow down:YES];
        [virtualHID control:NO];
        [virtualHID key:kHIDUsage_KeyboardDownArrow down:NO];
    } else if (button == 2) { // Launchpad
        if (!down) return;
        [self openApplication:@"Launchpad"];
    }
    
//    if (down) printf("Button %d down\n", button);
//    else printf("Button %d up\n", button);
}

- (void)movedX:(int16_t)x Y:(int16_t)y manager:(HMManager*)manager {
    if ([manager isMouseDown:1]) {
        [self rotateWheel:CGPointMake(x, y)];
    } else {
        [virtualHID moveX:x Y:y];
    }
//    printf("move (%d, %d)\n", x, y);
}

- (void)wheelVertical:(int16_t)vertical manager:(HMManager*)manager {
    [self adjustVolume:vertical*0.03];
}

- (void)wheelHorizontal:(int16_t)horizontal manager:(HMManager*)manager {
    uint8_t code = kHIDUsage_KeyboardLeftArrow;
    if (horizontal < 0) code = kHIDUsage_KeyboardRightArrow;
    [virtualHID control:YES];
    [virtualHID key:code down:YES];
    [virtualHID control:NO];
    [virtualHID key:code down:NO];
}

- (void)rotateWheel:(CGPoint)offset {
    CGEventRef scroll = CGEventCreateScrollWheelEvent2(nil, kCGScrollEventUnitPixel, 2, offset.y * 1.5, offset.x * 1.5, 0);
//    CGEventRef scroll = CGEventCreateScrollWheelEvent(nil, kCGScrollEventUnitPixel, 2, offset.y * 1.5, offset.x * 1.5);
    CGEventPost(kCGHIDEventTap, scroll);
    CFRelease(scroll);
}

// 音量調整
-(void)adjustVolume:(CGFloat)offset {
    AudioObjectPropertyAddress addr;
    addr.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    addr.mScope = kAudioObjectPropertyScopeGlobal;
    addr.mElement = kAudioObjectPropertyElementMaster;

    AudioDeviceID outputDeviceID;
    UInt32 size = sizeof(AudioDeviceID);
    OSStatus err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, &outputDeviceID);

    if (err == noErr) {
        AudioObjectPropertyAddress addr;
        addr.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
        addr.mScope = kAudioObjectPropertyScopeOutput;
        addr.mElement = kAudioObjectPropertyElementMaster;
        Float32 volume;

        // 音量を取得
        AudioObjectGetPropertyData(outputDeviceID, &addr, 0, NULL, &size, &volume);
        
        // 音量を設定
        size = sizeof(Float32);
        volume += offset;
        AudioObjectSetPropertyData(outputDeviceID, &addr, 0, NULL, size, &volume);
    }
}

-(void)openApplication:(NSString*)application {
    NSString *command = [NSString stringWithFormat:@"open -a \"%@\"", application];
    system([command UTF8String]);
}


@end
