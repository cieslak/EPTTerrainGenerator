//
//  EPTViewController.h
//  EPTerrain
//
//  Created by Chris Cieslak on 5/14/14.
//  Copyright (c) 2014 Electropuf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPTViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)regenerateTouched:(id)sender;
- (IBAction)roughnessChanged:(id)sender;

@end
