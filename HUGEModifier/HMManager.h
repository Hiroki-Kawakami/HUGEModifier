//
//  HMManager.h
//  HUGEModifier
//
//  Created by hiroki on 2020/09/17.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HMProfile;

@interface HMManager : NSObject

@property (retain, nonatomic) HMProfile *currentProfile;

+ (HMManager *)sharedManager;

- (void)open;
- (BOOL)isMouseDown:(uint8_t)button;

@end

NS_ASSUME_NONNULL_END
