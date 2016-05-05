//
//  Quaternion.h
//  OBESDK_iOS
//
//  Created by Henry Serrano on 3/14/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBEQuaternion : NSObject

@property float w, x, y, z;
@property float roll, yaw, pitch;

//- (id)initWithW:(float)w X:(float)x Y:(float)y Z:(float)z;

@end
