//
//  HMVirtualHID.h
//  HUGEModifier
//
//  Created by hiroki on 2020/09/23.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDUsageTables.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMVirtualHID : NSObject

+ (HMVirtualHID *)shared;
- (void)button:(uint8_t)button down:(BOOL)down;
- (void)moveX:(uint8_t)x Y:(uint8_t)y;
- (void)wheelVertical:(uint8_t)vertical Horizontal:(uint8_t)horizontal;

- (void)control:(BOOL)down;
- (void)command:(BOOL)down;
- (void)shift:(BOOL)down;
- (void)option:(BOOL)down;
- (void)key:(uint8_t)code down:(BOOL)down;

@end

NS_ASSUME_NONNULL_END
