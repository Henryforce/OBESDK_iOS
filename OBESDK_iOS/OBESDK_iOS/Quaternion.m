//
//  Quaternion.m
//  OBESDK_iOS
//
//  Created by Henry Serrano on 3/14/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import "Quaternion.h"

@implementation Quaternion

- (id)initWithW:(float)w X:(float)x Y:(float)y Z:(float)z{
    if (self = [super init]) {
        // initializer logic
        _w = w; _x = x; _y = y; _z = z;
    }
    return self;
}

@end
