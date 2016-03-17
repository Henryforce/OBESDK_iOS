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

#define OBEQuaternionLeft 0
#define OBEQuaternionRight 1
#define OBEQuaternionCenter 2

#define OBEMPUDataSize 20
#define OBEHapticDataSize 7

union {
    float float_variable;
    Byte temp_array[4];
} floatStruct;

@implementation OBE

- (id)initWithDelegate:(id<OBEDelegate>)delegate{
    if (self = [super init]) {
        // initializer logic
        if(delegate != nil){
            self.delegate = delegate;
        }
        peripherals = [[NSMutableArray alloc] init];
        manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        //NSLog(@"Init finished");
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
        NSLog(@"Sending");
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
        NSLog(@"Not sending");
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
    
    // NSMutableArray *peripherals = [self mutableArrayValueForKey:@"vimiMonitors"];
    //if( ![vimiMonitors containsObject:aPeripheral] ){
    
    [peripherals addObject:aPeripheral];
    
    if(_delegate == nil){
        return;
    }
    //const char *name = [[aPeripheral name] cStringUsingEncoding:[NSString defaultCStringEncoding]];
    //NotifyFoundOBE(name, (int)([peripherals count] - 1));
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
    
    //self.connected = @"Connected";
    isConnected = true;
    
    //const char *name = "Connected";
    //NotifyOBEConnected(name);
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
        
        /* Device Information Service */
        /*if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]){
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }*/
        /* OBE Service */
        if([aService.UUID isEqual:[CBUUID UUIDWithString:OBEService]]){
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
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
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:OBEQuaternionCharacteristic]]){
        //NSString *auxString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        //NSLog(@"Received %@", auxString); auxString = nil;
        
        if([characteristic.value length] == OBEMPUDataSize){
            
            NSData *quaternionData = [characteristic value];
            Byte *buffer = malloc(sizeof(Byte) * OBEMPUDataSize);
            [quaternionData getBytes:buffer length:OBEMPUDataSize];
            
            //[self bufferToQuaternionStruct:buffer];
            [self assignBuffer:buffer withIdentifier:buffer[18]];
            if(buffer[18] == OBEQuaternionRight){
                Byte auxByte = buffer[18];
                _Button1 = (auxByte & 0x01) ? true : false;
                _Button2 = (auxByte & 0x02) ? true : false;
                _Button3 = (auxByte & 0x04) ? true : false;
                _Button4 = (auxByte & 0x08) ? true : false;
            }
            
            free(buffer);
            
            //[_delegate onQuaternionUpdated:QuaternionLeft W:W X:X Y:Y Z:Z];
        }
    }
}

#pragma mark User Functions

- (float) calculatePitch:(float) ax :(float) ay :(float) az{
    float localPitch = 0.0f, squareResult = 0.0f;
    
    squareResult = sqrtf(ay * ay + az * az);
    localPitch = atan2f(-ax, squareResult); // pitch in radians
    //localPitch = localPitch * 57.2957f; // pitch in degrees
    
    return localPitch;
}

- (float) calculateRoll:(float)ay :(float)az{
    float localRoll = 0.0f;
    
    localRoll = atan2f(ay, az); // roll in radians
    //localRoll = localRoll * 57.2957f; // roll in degrees
    
    return localRoll;
}

- (float) calculateYaw:(float)roll :(float)pitch :(float)mx :(float)my :(float) mz{
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

- (Quaternion *) calculateQuaternion:(float) roll :(float) pitch :(float) yaw{
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
    
    Quaternion *auxQ = [[Quaternion alloc] initWithW:w X:x Y:y Z:z];
    
    return auxQ;
}

- (void) bufferToQuaternionStruct:(Byte *)buffer{
    floatStruct.temp_array[0] = buffer[0];
    floatStruct.temp_array[1] = buffer[1];
    floatStruct.temp_array[2] = buffer[2];
    floatStruct.temp_array[3] = buffer[3];
    W = floatStruct.float_variable;
    
    floatStruct.temp_array[0] = buffer[4];
    floatStruct.temp_array[1] = buffer[5];
    floatStruct.temp_array[2] = buffer[6];
    floatStruct.temp_array[3] = buffer[7];
    X = floatStruct.float_variable;
    
    floatStruct.temp_array[0] = buffer[8];
    floatStruct.temp_array[1] = buffer[9];
    floatStruct.temp_array[2] = buffer[10];
    floatStruct.temp_array[3] = buffer[11];
    Y = floatStruct.float_variable;
    
    floatStruct.temp_array[0] = buffer[12];
    floatStruct.temp_array[1] = buffer[13];
    floatStruct.temp_array[2] = buffer[14];
    floatStruct.temp_array[3] = buffer[15];
    Z = floatStruct.float_variable;
}

- (void) assignBuffer:(Byte *)buffer withIdentifier:(int) identifier{
    switch(identifier){
        case OBEQuaternionLeft:
            _axLeft = (float)((int16_t)((buffer[0] << 8) | buffer[1])); _axLeft /= 32768.0f;
            _ayLeft = (float)((int16_t)((buffer[2] << 8) | buffer[3])); _ayLeft /= 32768.0f;
            _azLeft = (float)((int16_t)((buffer[4] << 8) | buffer[5])); _azLeft /= 32768.0f;
            _gxLeft = (float)((int16_t)((buffer[6] << 8) | buffer[7])); _gxLeft /= 32768.0f;
            _gyLeft = (float)((int16_t)((buffer[8] << 8) | buffer[9])); _gyLeft /= 32768.0f;
            _gzLeft = (float)((int16_t)((buffer[10] << 8) | buffer[11])); _gzLeft /= 32768.0f;
            _mxLeft = (float)((int16_t)((buffer[12] << 8) | buffer[13])); _mxLeft /= 32768.0f;
            _myLeft = (float)((int16_t)((buffer[14] << 8) | buffer[15])); _myLeft /= 32768.0f;
            _mzLeft = (float)((int16_t)((buffer[16] << 8) | buffer[17])); _mzLeft /= 32768.0f;
            break;
        case OBEQuaternionRight:
            _axRight = (float)((int16_t)((buffer[0] << 8) | buffer[1])); _axRight /= 32768.0f;
            _ayRight = (float)((int16_t)((buffer[2] << 8) | buffer[3])); _ayRight /= 32768.0f;
            _azRight = (float)((int16_t)((buffer[4] << 8) | buffer[5])); _azRight /= 32768.0f;
            _gxRight = (float)((int16_t)((buffer[6] << 8) | buffer[7])); _gxRight /= 32768.0f;
            _gyRight = (float)((int16_t)((buffer[8] << 8) | buffer[9])); _gyRight /= 32768.0f;
            _gzRight = (float)((int16_t)((buffer[10] << 8) | buffer[11])); _gzRight /= 32768.0f;
            _mxRight = (float)((int16_t)((buffer[12] << 8) | buffer[13])); _mxRight /= 32768.0f;
            _myRight = (float)((int16_t)((buffer[14] << 8) | buffer[15])); _myRight /= 32768.0f;
            _mzRight = (float)((int16_t)((buffer[16] << 8) | buffer[17])); _mzRight /= 32768.0f;
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

@end
