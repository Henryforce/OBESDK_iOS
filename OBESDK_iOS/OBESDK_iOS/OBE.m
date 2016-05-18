//
//  OBESDK_iOS.m
//  OBESDK_iOS
//
//  Created by Henry Serrano on 2/25/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import "OBE.h"

#define OBEService @"0003cbbb-0000-1000-8000-00805F9B0131"
#define OBEQuaternionCharacteristic @"0003cbb2-0000-1000-8000-00805F9B0131"
#define OBEPresetCharacteristic @"0003cbb3-0000-1000-8000-00805F9B0131"
#define OBEHapticCharacteristic @"0003cbb1-0000-1000-8000-00805F9B0131"

#define BatteryService @"180F"
#define BatteryLevelCharacteristic @"2A19"

#define OBEQuaternionLeft 0
#define OBEQuaternionRight 1
#define OBEQuaternionCenter 2

#define OBEMPUDataSize 20
#define OBEHapticDataSize 7

#define alpha 0.1f
#define alphaComplement 0.9f // alphaComplement = (1.0f - alpha)

/*union {
    float float_variable;
    Byte temp_array[4];
} floatStruct;*/

@implementation OBE

- (id)initWithDelegate:(id<OBEDelegate>)delegate{
    if (self = [super init]) {
        // initializer logic
        if(delegate != nil){
            self.delegate = delegate;
        }
        peripherals = [[NSMutableArray alloc] init];
        manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        _leftHand = [[OBEQuaternion alloc] init];
        _rightHand = [[OBEQuaternion alloc] init];
        _quaternionCenter = [[OBEQuaternion alloc] init];
    }
    return self;
}

#pragma mark Main Functions

- (void) startScanning{
    [self startScan];
}

- (void) connectToOBE:(int)index{
    if([peripherals count] > index){
        
        [self stopScan];
        
        obePeripheral = [peripherals objectAtIndex:index];
        [manager connectPeripheral:obePeripheral options:nil];
    }
}

- (void) disconnectFromOBE{
    if(obePeripheral != nil){
        [manager cancelPeripheralConnection:obePeripheral];
        [obePeripheral setDelegate:nil];
        obePeripheral = nil;
    }
}

- (void) updateMotorState{
    if((obePeripheral != nil) && (hapticCH != nil)){
        //NSLog(@"Sending");
        // send status command
        dispatch_async(dispatch_get_global_queue(0,0), ^{//normal priority
            
            const int bufferSize = 7;
            
            Byte motor1 = (Byte)(_Motor1 * 255.0f);
            Byte motor2 = (Byte)(_Motor2 * 255.0f);
            Byte motor3 = (Byte)(_Motor3 * 255.0f);
            Byte motor4 = (Byte)(_Motor4 * 255.0f);
            
            Byte auxByte[bufferSize];
            auxByte[0] = 0x7E;
            auxByte[1] = motor1;
            auxByte[2] = motor2;
            auxByte[3] = motor3;
            auxByte[4] = motor4;
            auxByte[5] = 0xFF;
            auxByte[6] = 0x00;
            
            NSData *auxData = [NSData dataWithBytes:auxByte length:bufferSize];
            
            [obePeripheral writeValue:auxData forCharacteristic:hapticCH type:CBCharacteristicWriteWithoutResponse];
            
            auxData = nil;
        });
    }else{
        //NSLog(@"Not sending");
    }
}

#pragma mark - Start/Stop Scan methods

/*
 Request CBCentralManager to scan for heart rate peripherals using service UUID 0x180D
 */
- (void) startScan{
    
    //[manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"180D"]] options:nil];
    [manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:OBEService]] options:nil];
    
    // make sure we stop scanning after 5 seconds if no device was found
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(stopScanning:) userInfo:nil repeats:NO];
    
    //testTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(stopScanning:) userInfo:nil repeats:YES];
}

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan{
    [manager stopScan];
    //[testTimer invalidate];
    //testTimer = nil;
}

- (void) stopScanning:(id)sender{
    NSTimer *timer = (NSTimer *)sender;
    [timer invalidate];
    //NSLog(@"Timer stopped scanning");
    
    [self stopScan];
}

#pragma mark - CBCentralManager delegate methods

/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central{
    //char * managerStrings[]={ "Unknown", "Resetting", "Unsupported", "Unauthorized", "PoweredOff", "PoweredOn" };
    
    //NSString *newstring = [NSString stringWithFormat:@"Manager State: %s", managerStrings[central.state]];
    //NSLog(@"%@", newstring);
}

/*
 Invoked when the central discovers peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    [peripherals addObject:aPeripheral];
    
    if(_delegate == nil){
        return;
    }
    
    [_delegate onOBEFound:aPeripheral.name Index:(int)([peripherals count] - 1)];
    
    //stop at the sight of the first device
    //[self stopScan];
    //}
    
    /* Retreive already known devices */
    /*if(autoConnect){
     [manager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
    }*/
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals{
    //NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    //[self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    /*if([peripherals count] >=1){
     peripheral = [peripherals objectAtIndex:0];
     
     [manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
     }*/
}

/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral{
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
    
    isConnected = true;
    
    if(_delegate == nil){
        return;
    }
    [_delegate onOBEConnected:aPeripheral.name];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error{
    //NSLog(@"Disconnected");
    if(_delegate == nil){
        return;
    }
    [_delegate onOBEDisconnected:aPeripheral.name];
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error{
    //NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    
    if( obePeripheral ){
        [obePeripheral setDelegate:nil];
        obePeripheral = nil;
    }
}

#pragma mark CBPeripheral Delegate

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error{
    for (CBService *aService in aPeripheral.services){
        //NSLog(@"Service found with UUID: %@", aService.UUID);
        
        // Battery
        if([aService.UUID isEqual:[CBUUID UUIDWithString:BatteryService]]){
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* OBE Service */
        if([aService.UUID isEqual:[CBUUID UUIDWithString:OBEService]]){
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:BatteryService]]){
        for (CBCharacteristic *aChar in service.characteristics){
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:BatteryLevelCharacteristic]]){
                [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:OBEService]]){
        for (CBCharacteristic *aChar in service.characteristics){
            /* Read DATA Characteristic */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:OBEQuaternionCharacteristic]]){
                
                [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
                
            }else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:OBEHapticCharacteristic]]){
                
                hapticCH = aChar;
                
            }
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    // If delegate is nil, do nothing
    if(_delegate == nil){
        return;
    }
    
    /* Data received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BatteryLevelCharacteristic]]){
        if([characteristic.value length] > 0){
            //NSLog(@"Battery Length %lu", [characteristic.value length]);
            NSData *batteryData = characteristic.value;
            Byte *dataArray = (Byte *)malloc(sizeof(Byte) * 1);
            [batteryData getBytes:dataArray length:1];
            
            // This could be optimized
            int level = dataArray[0];
            float flevel = level;
            flevel /= 100.0f;
            
            [_delegate onBatteryUpdated:flevel];
            
            free(dataArray);
        }
    }
    
    /* Data received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:OBEQuaternionCharacteristic]]){
        
        if([characteristic.value length] == OBEMPUDataSize){
            
            NSData *quaternionData = [characteristic value];
            Byte *buffer = malloc(sizeof(Byte) * OBEMPUDataSize);
            [quaternionData getBytes:buffer length:OBEMPUDataSize];
            
            [self assignBuffer:buffer withIdentifier:buffer[18]];
            
            Byte auxByte = buffer[18];
            if(auxByte == OBEQuaternionCenter){
                
//                _Button1 = (auxByte & 0x01) ? true : false;
//                _Button2 = (auxByte & 0x02) ? true : false;
//                _Button3 = (auxByte & 0x04) ? true : false;
//                _Button4 = (auxByte & 0x08) ? true : false;
                _LogoButton = (buffer[19] & 0x01) ? true : false;
                
                // TODO: implement delegate with new buttons
                //[_delegate onButtonsUpdated];
                /*if(oldButtons != buffer[18]){ //if a button was pressed or unpressed
                    [_delegate onButtonsUpdated:_Button1 :_Button2 :_Button3 :_Button4];
                }
                oldButtons = buffer[18];*/
                
                float rollLeftAux = [OBEMath calculateRoll:(-1.0f * _azLeft) :_axLeft];
                float pitchLeftAux = -1.0f * [OBEMath calculatePitch:_ayLeft :_axLeft :(-1.0f * _azLeft)];
                _leftHand.roll = alpha * rollLeftAux + alphaComplement * _leftHand.roll;
                _leftHand.pitch = alpha * pitchLeftAux + alphaComplement * _leftHand.pitch;
                [self calculateQuaternion:_leftHand.roll :_leftHand.pitch :_leftHand.yaw :OBEQuaternionLeft];
                
                float rollRightAux = [OBEMath calculateRoll:_azRight :(-1.0f * _axRight)];
                float pitchRightAux = -1.0f * [OBEMath calculatePitch:_ayRight :_axRight :_azRight];
                _rightHand.roll = alpha * rollRightAux + alphaComplement * _rightHand.roll;
                _rightHand.pitch = alpha * pitchRightAux + alphaComplement * _rightHand.pitch;
                [self calculateQuaternion:_rightHand.roll :_rightHand.pitch :_rightHand.yaw :OBEQuaternionRight];
                
                [_delegate onButtonsUpdated];
                
                //[_delegate onQuaternionsUpdated:_leftHand :_rightHand :_quaternionCenter];
            }else if(auxByte == OBEQuaternionLeft){
                _LeftButton1 = (buffer[19] & 0x01) ? true : false;
                _LeftButton2 = (buffer[19] & 0x02) ? true : false;
                _LeftButton3 = (buffer[19] & 0x04) ? true : false;
                _LeftButton4 = (buffer[19] & 0x08) ? true : false;
            }else if(auxByte == OBEQuaternionRight){
                _RightButton1 = (buffer[19] & 0x01) ? true : false;
                _RightButton2 = (buffer[19] & 0x02) ? true : false;
                _RightButton3 = (buffer[19] & 0x04) ? true : false;
                _RightButton4 = (buffer[19] & 0x08) ? true : false;
            }
            
            free(buffer);
            
        }
    }
}

#pragma mark User Functions

- (void ) calculateQuaternion:(float) roll :(float) pitch :(float) yaw :(int) identifier{
    float sinHalfYaw = sinf(yaw / 2.0f);
    float cosHalfYaw = cosf(yaw / 2.0f);
    float sinHalfPitch = sinf(pitch/ 2.0f);
    float cosHalfPitch = cosf(pitch / 2.0f);
    float sinHalfRoll = sinf(roll / 2.0f);
    float cosHalfRoll = cosf(roll / 2.0f);
    
    float x = -cosHalfRoll * sinHalfPitch * sinHalfYaw + cosHalfPitch * cosHalfYaw * sinHalfRoll;
    float y = cosHalfRoll * cosHalfYaw * sinHalfPitch + sinHalfRoll * cosHalfPitch * sinHalfYaw;
    float z = cosHalfRoll * cosHalfPitch * sinHalfYaw - sinHalfRoll * cosHalfYaw * sinHalfPitch;
    float w = cosHalfRoll * cosHalfPitch * cosHalfYaw + sinHalfRoll * sinHalfPitch * sinHalfYaw;
    
    if(identifier == OBEQuaternionLeft){
        _leftHand.w = w; _leftHand.x = x;
        _leftHand.y = y; _leftHand.z = z;
    }else if(identifier == OBEQuaternionRight){
        _rightHand.w = w; _rightHand.x = x;
        _rightHand.y = y; _rightHand.z = z;
    }else if(identifier == OBEQuaternionCenter){
        _quaternionCenter.w = w; _quaternionCenter.x = x;
        _quaternionCenter.y = y; _quaternionCenter.z = z;
    }
}

- (void) assignBuffer:(Byte *)buffer withIdentifier:(int)identifier{
    switch(identifier){
        case OBEQuaternionLeft:
            _axLeft = [self bytesToFloat:buffer[0] :buffer[1]];
            _ayLeft = [self bytesToFloat:buffer[2] :buffer[3]];
            _azLeft = [self bytesToFloat:buffer[4] :buffer[5]];
            _gxLeft = [self bytesToFloat:buffer[6] :buffer[7]];
            _gyLeft = [self bytesToFloat:buffer[8] :buffer[9]];
            _gzLeft = [self bytesToFloat:buffer[10] :buffer[11]];
            _mxLeft = [self bytesToFloat:buffer[12] :buffer[13]];
            _myLeft = [self bytesToFloat:buffer[14] :buffer[15]];
            _mzLeft = [self bytesToFloat:buffer[16] :buffer[17]];
            break;
        case OBEQuaternionRight:
            _axRight = [self bytesToFloat:buffer[0] :buffer[1]];
            _ayRight = [self bytesToFloat:buffer[2] :buffer[3]];
            _azRight = [self bytesToFloat:buffer[4] :buffer[5]];
            _gxRight = [self bytesToFloat:buffer[6] :buffer[7]];
            _gyRight = [self bytesToFloat:buffer[8] :buffer[9]];
            _gzRight = [self bytesToFloat:buffer[10] :buffer[11]];
            _mxRight = [self bytesToFloat:buffer[12] :buffer[13]];
            _myRight = [self bytesToFloat:buffer[14] :buffer[15]];
            _mzRight = [self bytesToFloat:buffer[16] :buffer[17]];
            break;
        case OBEQuaternionCenter:
            _axCenter = (float)((int16_t)((buffer[0] << 8) | buffer[1])); _axCenter /= 32768.0f;
            _ayCenter = (float)((int16_t)((buffer[2] << 8) | buffer[3])); _ayCenter /= 32768.0f;
            _azCenter = (float)((int16_t)((buffer[4] << 8) | buffer[5])); _azCenter /= 32768.0f;
            _gxCenter = (float)((int16_t)((buffer[6] << 8) | buffer[7])); _gxCenter /= 32768.0f;
            _gyCenter = (float)((int16_t)((buffer[8] << 8) | buffer[9])); _gyCenter /= 32768.0f;
            _gzCenter = (float)((int16_t)((buffer[10] << 8) | buffer[11])); _gzCenter /= 32768.0f;
            _mxCenter = (float)((int16_t)((buffer[12] << 8) | buffer[13])); _mxCenter /= 32768.0f;
            _myCenter = (float)((int16_t)((buffer[14] << 8) | buffer[15])); _myCenter /= 32768.0f;
            _mzCenter = (float)((int16_t)((buffer[16] << 8) | buffer[17])); _mzCenter /= 32768.0f;
            break;
    }
}

- (float) bytesToFloat:(Byte)byteLS :(Byte)byteMS{
    float aux = (float)((int16_t)((byteLS << 8) | byteMS));
    aux /= 32768.0f;
    return aux;
}

@end
