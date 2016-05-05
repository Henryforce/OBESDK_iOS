//
//  OBEMath.h
//  OBESDK_iOS
//
//  Created by Henry Serrano on 4/10/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBEMath : NSObject

+ (float) calculatePitch:(float) ax :(float) ay :(float) az;
+ (float) calculateRoll:(float)ay :(float)az;
+ (float) calculateYaw:(float)roll :(float)pitch :(float)mx :(float)my :(float) mz;

@end
