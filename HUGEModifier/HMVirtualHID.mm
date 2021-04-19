//
//  HMVirtualHID.m
//  HUGEModifier
//
//  Created by hiroki on 2020/09/23.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import "HMVirtualHID.h"

#include <cstdlib>
#include <atomic>
#include <filesystem>
#include <iostream>
#include <pqrs/karabiner/driverkit/virtual_hid_device_driver.hpp>
#include <pqrs/karabiner/driverkit/virtual_hid_device_service.hpp>
#include <pqrs/local_datagram.hpp>
#include <thread>
#include <memory>

pqrs::karabiner::driverkit::virtual_hid_device_service::client *virtualhid_client;
std::mutex client_mutex;
bool keyboard_ready, pointing_ready;
pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::pointing_input mouseReport;
pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::keyboard_input keyboardReport;

@implementation HMVirtualHID {}

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
            std::cout << "VirtualHID requires root privilege" << std::endl;
            return nil;
        }
        
        pqrs::dispatcher::extra::initialize_shared_dispatcher();
        std::filesystem::path client_socket_file_path("/tmp/karabiner_driverkit_virtual_hid_device_service_client.sock");
        virtualhid_client = new pqrs::karabiner::driverkit::virtual_hid_device_service::client(client_socket_file_path);

        std::thread call_ready_thread([] {
            std::cout << "loading..." << std::endl;
            keyboard_ready = pointing_ready = false;
            while (true) {
                {
                    std::lock_guard<std::mutex> lock(client_mutex);
                    if (virtualhid_client) {
                        virtualhid_client->async_driver_loaded();
                        virtualhid_client->async_driver_version_matched();
                        virtualhid_client->async_virtual_hid_keyboard_ready();
                        virtualhid_client->async_virtual_hid_pointing_ready();
                    }
                }
                if (keyboard_ready && pointing_ready) {
                    std::cout << "VirtualHID ready." << std::endl;
                    break;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(500));
            }
        });
        
        virtualhid_client->connected.connect([] {
            std::cout << "connected" << std::endl;

            virtualhid_client->async_virtual_hid_keyboard_initialize(pqrs::hid::country_code::us);
            virtualhid_client->async_virtual_hid_pointing_initialize();
        });
        virtualhid_client->connect_failed.connect([](auto&& error_code) {
            std::cout << "connect_failed " << error_code << std::endl;
        });
        virtualhid_client->closed.connect([] {
            std::cout << "closed" << std::endl;
        });
        virtualhid_client->error_occurred.connect([](auto&& error_code) {
            std::cout << "error_occurred " << error_code << std::endl;
        });
        virtualhid_client->driver_loaded_response.connect([](auto&& driver_loaded) {
            static std::optional<bool> previous_value;

            if (previous_value != driver_loaded) {
                std::cout << "driver_loaded " << driver_loaded << std::endl;
                previous_value = driver_loaded;
            }
        });
        virtualhid_client->driver_version_matched_response.connect([](auto&& driver_version_matched) {
            static std::optional<bool> previous_value;

            if (previous_value != driver_version_matched) {
                std::cout << "driver_version_matched " << driver_version_matched << std::endl;
                previous_value = driver_version_matched;
            }
        });
        virtualhid_client->virtual_hid_keyboard_ready_response.connect([](auto&& ready) {
            if (ready) keyboard_ready = true;
        });
        virtualhid_client->virtual_hid_pointing_ready_response.connect([](auto&& ready) {
            if (ready) pointing_ready = true;
        });
        
        auto clean = [] {
            std::cout << "cleaning..." << std::endl;
            delete virtualhid_client;
            pqrs::dispatcher::extra::terminate_shared_dispatcher();
            exit(0);
        };
        std::atexit(clean);
        std::signal(SIGINT, exit);
        std::signal(SIGTERM, exit);

        virtualhid_client->async_start();
        call_ready_thread.join();
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
    pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::pointing_input tmpReport = mouseReport;
    tmpReport.x = x;
    tmpReport.y = y;
    [self postMouseReport:tmpReport];
}

- (void)wheelVertical:(uint8_t)vertical Horizontal:(uint8_t)horizontal {
    pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::pointing_input tmpReport = mouseReport;
    tmpReport.vertical_wheel = vertical;
    tmpReport.horizontal_wheel = horizontal;
    [self postMouseReport:tmpReport];
}

- (void)postMouseReport:(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::pointing_input)report {
    std::lock_guard<std::mutex> lock(client_mutex);
    virtualhid_client->async_post_report(report);
}

- (void)command:(BOOL)down {
    if (down) keyboardReport.modifiers.insert(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_command);
    else keyboardReport.modifiers.erase(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_command);
}
- (void)control:(BOOL)down {
    if (down) keyboardReport.modifiers.insert(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_control);
    else keyboardReport.modifiers.erase(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_control);
}
- (void)shift:(BOOL)down {
    if (down) keyboardReport.modifiers.insert(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_shift);
    else keyboardReport.modifiers.erase(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_shift);
}
- (void)option:(BOOL)down {
    if (down) keyboardReport.modifiers.insert(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_option);
    else keyboardReport.modifiers.erase(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::modifier::left_option);
}

- (void)key:(uint8_t)code down:(BOOL)down {
    if (down) keyboardReport.keys.insert(code);
    else keyboardReport.keys.erase(code);

    [self postKeyboardReport:keyboardReport];
}
- (void)postKeyboardReport:(pqrs::karabiner::driverkit::virtual_hid_device_driver::hid_report::keyboard_input )report {
    std::lock_guard<std::mutex> lock(client_mutex);
    virtualhid_client->async_post_report(report);
}


@end
