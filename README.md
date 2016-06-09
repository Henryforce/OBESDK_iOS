# OBESDK_iOS

This repository contains all the source code related to OBE's SDK for iOS.

**Installation**

In order to add OBE's SDK into your project, you must download the repository and add the OBE SDK Framework into your project.

**Use**

You can initialise the OBE SDK like this: (refer to the demo project)

	// make your view controller respond to the 'OBEDelegate' protocol
	OBE *obe = [[OBE alloc] initWithDelegate:self];
	
To start scanning for an OBE Jacket. Use the following code:

	[obe startScanning];
	
In order to read data from an OBE jacket. The following piece of code must be implemented inside your controller:

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
	
	}

	// There was a button pressed or unpressed. Check current button state manually.
	- (void) onButtonsUpdated{
		
	}
	
There are several addressable properties, such as:

* Motor1 (Float - Left hand Motor)
* Motor2 (Float - Right hand Motor)
* Motor3 (Float - Logo Motor)
* Motor4 (Float - Cerebrum Motor)
* QuaternionLeft (Quaternion - Left Hand)
* QuaternionRight (Quaternion - Right Hand)
* QuaternionCenter (Quaternion - Cerebrum)
* LeftButton1 (Boolean - Left Button on Left Hand)
* LeftButton2 (Boolean - Right Button on Left Hand)
* LeftButton3 (Boolean - Up Button on Left Hand)
* LeftButton4 (Boolean - Down Button on Left Hand)
* RightButton1 (Boolean - Left Button on Right Hand)
* RightButton2 (Boolean - Right Button on Right Hand)
* RightButton3 (Boolean - Up Button on Right Hand)
* RightButton4 (Boolean - Down Button on Right Hand)
* LogoButton (Boolean - Logo button)