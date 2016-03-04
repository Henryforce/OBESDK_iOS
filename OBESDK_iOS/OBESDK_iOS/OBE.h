//
//  OBESDK_iOS.h
//  OBESDK_iOS
//
//  Created by Henry Serrano on 2/25/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol OBEDelegate <NSObject>

- (void) onOBEFound:(NSString *)name Index:(int)index;
- (void) onOBEConnected:(NSString *)name;
- (void) onOBEDisconnected:(NSString *)name;
- (void) onQuaternionUpdated:(int) identifier W:(float)w X:(float)x Y:(float)y Z:(float)z;

@end

@interface OBE : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>{
    CBCentralManager *manager;
    CBPeripheral *obePeripheral;
    CBCharacteristic *hapticCH;
    
    NSMutableArray *peripherals;
    
    BOOL isConnected;
    float W,X,Y,Z;
}

@property id<OBEDelegate> delegate;

@property float Motor1;
@property float Motor2;
@property float Motor3;
@property float Motor4;

- (id)initWithDelegate:(id<OBEDelegate>)delegate;

- (void) startScanning;
- (void) connectToOBE:(int)index;
- (void) disconnectFromOBE;
- (void) updateMotorState;

@end
