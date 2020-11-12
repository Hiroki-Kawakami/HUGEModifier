//
//  HMWorkspace.h
//  HUGEModifier
//
//  Created by hiroki on 2020/09/29.
//  Copyright © 2020 hiroki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HMManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMWorkspace : NSObject

@property (retain, nonatomic) HMManager *manager;

+ (HMWorkspace *)shared;

- (void)updateProfile;

@end

NS_ASSUME_NONNULL_END
