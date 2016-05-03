//
//  ViewController.h
//  OBESDKDemo_iOS
//
//  Created by Henry Serrano on 2/26/16.
//  Copyright © 2016 Machina Wearable Technology SAPI de CV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBESDK_iOS/OBE.h"
//#import "OBESDK_iOS/OBEQuaternion.h"

@interface ViewController : UIViewController<OBEDelegate>{
    OBE *obe;
}

//@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UILabel *rotatingLabel;

- (IBAction)search:(id)sender;
- (IBAction)toggleMotors:(id)sender;

@end

