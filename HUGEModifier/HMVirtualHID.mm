//
//  HMVirtualHID.m
//  HUGEModifier
//
//  Created by hiroki on 2020/09/23.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import "HMVirtualHID.h"

#include "karabiner_virtual_hid_device_methods.hpp"
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDElement.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDQueue.h>
#include <IOKit/hid/IOHIDValue.h>
#include <IOKit/hidsystem/IOHIDShared.h>
#include <IOKit/hidsystem/ev_keymap.h>
#include <cmath>
#include <iostream>
#include <thread>

@implementation HMVirtualHID {
    kern_return_t kr;
    io_connect_t connect;
    pqrs::karabiner_virtual_hid_device::hid_report::pointing_input mouseReport;
    pqrs::karabiner_virtual_hid_device::hid_report::keyboard_input keyboardReport;
}

static HMVirtualHID *_shared = nil;

+ (HMVirtualHID *)shared {
    if (!_shared) _shared = [HMVirtualHID new];
    return _shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (getuid() != 0) {
            NSLog(@"VirtualHID requires root privilege");
            return nil;
        }
        
        connect = IO_OBJECT_NULL;
        auto service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceNameMatching(pqrs::karabiner_virtual_hid_device::get_virtual_hid_root_name()));
        if (!service) {
            std::cerr << "IOServiceGetMatchingService error" << std::endl;
            return nil;
        }
        
        kr = IOServiceOpen(service, mach_task_self(), kIOHIDServerConnectType, &connect);
        if (kr != KERN_SUCCESS) {
            std::cerr << "IOServiceOpen error" << std::endl;
            return nil;
        }

        kr = pqrs::karabiner_virtual_hid_device_methods::initialize_virtual_hid_pointing(connect);
        if (kr != KERN_SUCCESS) {
          std::cerr << "initialize_virtual_hid_pointing error" << std::endl;
        }
        
        pqrs::karabiner_virtual_hid_device::properties::keyboard_initialization properties;
        kr = pqrs::karabiner_virtual_hid_device_methods::initialize_virtual_hid_keyboard(connect, properties);
        if (kr != KERN_SUCCESS) {
          std::cerr << "initialize_virtual_hid_keyboard error" << std::endl;
        }
        
        while (true) {
            std::cout << "Checking virtual_hid_keyboard is ready..." << std::endl;

            bool ready;
            kr = pqrs::karabiner_virtual_hid_device_methods::is_virtual_hid_keyboard_ready(connect, ready);
            if (kr != KERN_SUCCESS) {
                std::cerr << "is_virtual_hid_keyboard_ready error: " << kr << std::endl;
            } else {
                if (ready) {
                    std::cout << "virtual_hid_keyboard is ready." << std::endl;
                    break;
                }
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
    }
    return self;
}

- (void)button:(uint8_t)button down:(BOOL)down {
    uint8_t modifier = 1 << button;
    if (down) mouseReport.buttons.insert(modifier);
    else mouseReport.buttons.erase(modifier);
    [self postMouseReport:mouseReport];
}

- (void)moveX:(uint8_t)x Y:(uint8_t)y {
    static pqrs::karabiner_virtual_hid_device::hid_report::pointing_input tmpReport;
    tmpReport = mouseReport;
    tmpReport.x = x;
    tmpReport.y = y;
    [self postMouseReport:tmpReport];
}

- (void)wheelVertical:(uint8_t)vertical Horizontal:(uint8_t)horizontal {
    static pqrs::karabiner_virtual_hid_device::hid_report::pointing_input tmpReport;
    tmpReport = mouseReport;
    tmpReport.vertical_wheel = vertical;
    tmpReport.horizontal_wheel = horizontal;
    [self postMouseReport:tmpReport];
}

- (void)postMouseReport:(pqrs::karabiner_virtual_hid_device::hid_report::pointing_input)report {
    kr = pqrs::karabiner_virtual_hid_device_methods::post_pointing_input_report(connect, report);
    if (kr != KERN_SUCCESS) {
        std::cerr << "post_pointing_input_report error" << std::endl;
    }
}

- (void)command:(BOOL)down {
    if (down) keyboardReport.modifiers.insert(pqrs::karabiner_virtual_hid_device::hid_report::modifier::left_command);
    else keyboardReport.modifiers.erase(pqrs::karabiner_virtual_hid_device::hid_report::modifier::left_command);
}
- (void)control:(BOOL)down {
    if (down) keyboardReport.modifiers.insert(pqrs::karabiner_virtual_hid_device::hid_report::modifier::left_control);
    else keyboardReport.modifiers.erase(pqrs::karabiner_virtual_hid_device::hid_report::modifier::left_control);
}

- (void)key:(uint8_t)code down:(BOOL)down {
    if (down) keyboardReport.keys.insert(code);
    else keyboardReport.keys.erase(code);
    
    [self postKeyboardReport:keyboardReport];
}
- (void)postKeyboardReport:(pqrs::karabiner_virtual_hid_device::hid_report::keyboard_input )report {
    kr = pqrs::karabiner_virtual_hid_device_methods::post_keyboard_input_report(connect, report);
    if (kr != KERN_SUCCESS) {
        std::cerr << "post_keyboard_input_report error" << std::endl;
    }
}


@end
