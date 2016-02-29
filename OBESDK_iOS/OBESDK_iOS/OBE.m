//
//  OBESDK_iOS.m
//  OBESDK_iOS
//
//  Created by Henry Serrano on 2/25/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import "OBE.h"

#define OBEService @"0003cbbb-0000-1000-8000-00805F9B0131"
#define OBEQuaternionCharacteristic_Left @"0003cbb2-0000-1000-8000-00805F9B0131"
#define OBEQuaternionCharacteristic_Right @"0003cbb3-0000-1000-8000-00805F9B0131"
#define OBEQuaternionCharacteristic_Center @"0003cbb4-0000-1000-8000-00805F9B0131"

#define QuaternionLeft 0
#define QuaternionRight 1
#define QuaternionCenter 2

union {
    float float_variable;
    Byte temp_array[4];
} Quaternion;

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
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:OBEQuaternionCharacteristic_Left]]){
                
                [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
                
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
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:OBEQuaternionCharacteristic_Left]]){
        //NSString *auxString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        //NSLog(@"Received %@", auxString); auxString = nil;
        
        if([characteristic.value length] == 16){
            
            NSData *quaternionData = [characteristic value];
            Byte *buffer = malloc(sizeof(Byte) * 16);
            [quaternionData getBytes:buffer length:16];
            
            [self bufferToQuaternionStruct:buffer];
            
            free(buffer);
            
            [_delegate onQuaternionUpdated:QuaternionLeft W:W X:X Y:Y Z:Z];
        }
    }
}

#pragma mark User Functions

- (void) bufferToQuaternionStruct:(Byte *)buffer{
    Quaternion.temp_array[0] = buffer[0];
    Quaternion.temp_array[1] = buffer[1];
    Quaternion.temp_array[2] = buffer[2];
    Quaternion.temp_array[3] = buffer[3];
    W = Quaternion.float_variable;
    
    Quaternion.temp_array[0] = buffer[4];
    Quaternion.temp_array[1] = buffer[5];
    Quaternion.temp_array[2] = buffer[6];
    Quaternion.temp_array[3] = buffer[7];
    X = Quaternion.float_variable;
    
    Quaternion.temp_array[0] = buffer[8];
    Quaternion.temp_array[1] = buffer[9];
    Quaternion.temp_array[2] = buffer[10];
    Quaternion.temp_array[3] = buffer[11];
    Y = Quaternion.float_variable;
    
    Quaternion.temp_array[0] = buffer[12];
    Quaternion.temp_array[1] = buffer[13];
    Quaternion.temp_array[2] = buffer[14];
    Quaternion.temp_array[3] = buffer[15];
    Z = Quaternion.float_variable;
}

@end
