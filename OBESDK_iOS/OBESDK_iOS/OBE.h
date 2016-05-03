//
//  OBESDK_iOS.h
//  OBESDK_iOS
//
//  Created by Henry Serrano on 2/25/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "OBEQuaternion.h"
#import "OBEMath.h"

@protocol OBEDelegate <NSObject>

- (void) onOBEFound:(NSString *)name Index:(int)index;
- (void) onOBEConnected:(NSString *)name;
- (void) onOBEDisconnected:(NSString *)name;
- (void) onQuaternionsUpdated:(OBEQuaternion *)left :(OBEQuaternion *)right :(OBEQuaternion *)center;
- (void) onButtonsUpdated:(BOOL)button1 :(BOOL)button2 :(BOOL)button3 :(BOOL) button4;

@end

@interface OBE : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>{
    CBCentralManager *manager;
    CBPeripheral *obePeripheral;
    CBCharacteristic *hapticCH;
    
    NSMutableArray *peripherals;
    
    BOOL isConnected;
    float W,X,Y,Z;
    Byte oldButtons;
}

@property id<OBEDelegate> delegate;

@property float Motor1, Motor2, Motor3, Motor4;

@property float axLeft, ayLeft, azLeft;
@property float gxLeft, gyLeft, gzLeft;
@property float mxLeft, myLeft, mzLeft;

@property float axRight, ayRight, azRight;
@property float gxRight, gyRight, gzRight;
@property float mxRight, myRight, mzRight;

@property float axCenter, ayCenter, azCenter;
@property float gxCenter, gyCenter, gzCenter;
@property float mxCenter, myCenter, mzCenter;

@property float rollLeft, pitchLeft, yawLeft;
@property float rollRight, pitchRight, yawRight;
@property float rollCenter, pitchCenter, yawCenter;

@property OBEQuaternion *leftHand, *rightHand, *quaternionCenter;

@property bool Button1, Button2, Button3, Button4;

- (id)initWithDelegate:(id<OBEDelegate>)delegate;

- (void) startScanning;
- (void) connectToOBE:(int)index;
- (void) disconnectFromOBE;
- (void) updateMotorState;

@end
