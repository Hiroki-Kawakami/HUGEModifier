//
//  HMCadProfile.m
//  HUGEModifier
//
//  Created by hiroki on 2020/09/29.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import "HMCadProfile.h"

@implementation HMCadProfile

- (void)clicked:(uint8_t)button isDown:(BOOL)down manager:(HMManager*)manager {
    
    if (button == 6) {
        [virtualHID button:0 down:down];
    } else if (button == 7) {
        [virtualHID button:1 down:down];
    } else if (button == 1) {
        [virtualHID button:2 down:down];
    } else if (button == 5) {
    } else {
        [super clicked:button isDown:down manager:manager];
    }
}

- (void)movedX:(int16_t)x Y:(int16_t)y manager:(HMManager *)manager {
    if ([manager isMouseDown:5]) {
        [self rotateWheel:CGPointMake(x, y)];
    } else {
        [virtualHID moveX:x Y:y];
    }
}

@end
