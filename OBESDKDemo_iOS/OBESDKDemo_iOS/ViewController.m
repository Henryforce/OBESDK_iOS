//
//  ViewController.m
//  OBESDKDemo_iOS
//
//  Created by Henry Serrano on 2/26/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    obe = [[OBE alloc] initWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [obe disconnectFromOBE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark OBEDelegate

- (void) onOBEFound:(NSString *)name Index:(int)index{
    NSLog(@"OBE Found: %@", name);
    
    // connect upon discovering first OBE
    [obe connectToOBE:index];
}

- (void) onOBEConnected:(NSString *)name{
    NSLog(@"Connected to: %@", name);
}

- (void) onOBEDisconnected:(NSString *)name{
    NSLog(@"Disconnected from: %@", name);
}

- (void) onBatteryUpdated:(float)batteryLevel{
    NSLog(@"Battery %f", batteryLevel); // percentage
}

// Quaternion data updated
- (void) onQuaternionsUpdated:(OBEQuaternion *)left :(OBEQuaternion *)right :(OBEQuaternion *)center{
    
    //CATransform3D rotationAndPerspectiveTransform = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate (CATransform3DIdentity, left.pitch, -1.0, 0.0, 0.0), CATransform3DRotate(CATransform3DIdentity, left.yaw, 0.0, 1.0, 0.0)), CATransform3DRotate(CATransform3DIdentity, left.roll, 0.0, 0.0, -1.0));
    
    //_rotatingLabel.layer.transform = rotationAndPerspectiveTransform;
    
}

// There was a button pressed or unpressed. Check current button state manually.
- (void) onButtonsUpdated{
    CATransform3D rotationAndPerspectiveTransform = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate (CATransform3DIdentity, obe.rightHand.pitch, -1.0, 0.0, 0.0), CATransform3DRotate(CATransform3DIdentity, obe.rightHand.yaw, 0.0, 1.0, 0.0)), CATransform3DRotate(CATransform3DIdentity, obe.rightHand.roll, 0.0, 0.0, -1.0));
    
    _rotatingLabel.layer.transform = rotationAndPerspectiveTransform;
    
    //NSLog(@"%f, %f", obe.rightHand.roll * 180 / 3.1416, obe.rightHand.pitch * 180 / 3.1416);
}

#pragma mark IBFunctions

- (IBAction)search:(id)sender{
    //obe = [[OBE alloc] init];
    //[obe setDelegate:self];
    
    [obe startScanning];
    
    NSLog(@"Scan started");
}

- (IBAction)toggleMotors:(id)sender{
    UISwitch *toggle = (UISwitch *)sender;
    
    float motorValue = toggle.isOn ? 1.0f : 0.0f;
    //NSLog(@"%f", motorValue);
    
    if(obe != nil){
        [obe setMotor1:motorValue];
        [obe setMotor2:motorValue];
        [obe setMotor3:motorValue];
        [obe setMotor4:motorValue];
        NSLog(@"%f", obe.Motor1);
        
        [obe updateMotorState];
    }
}

@end
