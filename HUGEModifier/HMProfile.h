//
//  HMProfile.h
//  HUGEModifier
//
//  Created by hiroki on 2020/09/29.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMVirtualHID.h"
#import "HMManager.h"

NS_ASSUME_NONNULL_BEGIN

struct VirtualButton {
    BOOL isDown;
    NSInteger count;
    NSTimeInterval last;
    CGEventRef event;
};

@interface HMProfile : NSObject {
    HMVirtualHID *virtualHID;
}

- (void)clicked:(uint8_t)button isDown:(BOOL)down manager:(HMManager*)manager;
- (void)movedX:(int16_t)x Y:(int16_t)y manager:(HMManager*)manager;
- (void)wheelVertical:(int16_t)vertical manager:(HMManager*)manager;
- (void)wheelHorizontal:(int16_t)horizontal manager:(HMManager*)manager;

- (void)rotateWheel:(CGPoint)offset;
-(void)openApplication:(NSString*)application;

@end

NS_ASSUME_NONNULL_END
