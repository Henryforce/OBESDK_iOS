//
//  OBEMath.m
//  OBESDK_iOS
//
//  Created by Henry Serrano on 4/10/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import "OBEMath.h"

@implementation OBEMath

/*******************************************************************************
* @name calculatePitch()
********************************************************************************
*
*   Summary:    This function calculates a Nerv's pitch. Integer to float is
*               recommended and employed to keep data resolution.
*
*   @param      ax      - x axis accelerometer value as a float
*   @param      ay      - y axis accelerometer value as a float
*   @param      az      - z axis accelerometer value as a float
*
*   @return     pitch   - The calculated pitch expressed in radians, as a float value
*
*   @todo       Optimise function
*
********************************************************************************/
+ (float) calculatePitch:(float) ax :(float) ay :(float) az{
    float localPitch = 0.0f, squareResult = 0.0f;
    
    squareResult = sqrtf(ay * ay + az * az);
    localPitch = atan2f(-ax, squareResult); // pitch in radians
    //localPitch = localPitch * 57.2957f; // pitch in degrees
    
    return localPitch;
}

/*******************************************************************************
* @name calculateRoll()
********************************************************************************
*
*   Summary:    This function calculates a Nerv's roll. Integer to float is
*               recommended and employed to keep data resolution.
*
*   @param      ay      - y axis accelerometer value as a float
*   @param      az      - z axis accelerometer value as a float
*
*   @return     roll    - The calculated roll expressed in radians, as a float value
*
*   @todo       Optimise function
*
********************************************************************************/
+ (float) calculateRoll:(float)ay :(float)az{
    float localRoll = 0.0f;
    
    localRoll = atan2f(ay, az); // roll in radians
    //localRoll = localRoll * 57.2957f; // roll in degrees
    
    return localRoll;
}

/*******************************************************************************
* @name calculateYaw()
********************************************************************************
*
*   Summary:    This function calculates a Nerv's yaw. Integer to float is
*               recommended and employed to keep data resolution.
*
*   @param      roll    - roll expressed in radians, as a float value
*               pitch   - pitch expressed in radians, as a float value
*               mx      - x axis magnetometer value as a float
*               my      - y axis magnetometer value as a float
*               mz      - z axis magnetometer value as a float
*
*   @return     yaw     - The calculated yaw expressed in radians, as a float value
*
*   @todo       Optimise function
*
********************************************************************************/
+ (float) calculateYaw:(float)roll :(float)pitch :(float)mx :(float)my :(float) mz{
    float localYaw = 0.0f, upper = 0.0f, lower = 0.0f, sinRoll = 0.0f, cosRoll = 0.0f,
    sinPitch = 0.0f, cosPitch = 0.0f;
    
    sinRoll = sinf(roll);
    cosRoll = cosf(roll); // / 57.2957f
    sinPitch = sinf(pitch);
    cosPitch = cosf(pitch);
    
    upper = mz * sinRoll - my * cosRoll;
    lower = mx * cosPitch + my * sinPitch * sinRoll +
    mz * sinPitch * cosRoll;
    localYaw = atan2f(upper, lower); // yaw in radians
    //localYaw = localYaw * 57.2957f; // yaw in angles
    
    return localYaw;
}

@end
