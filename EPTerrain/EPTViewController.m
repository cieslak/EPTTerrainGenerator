//
//  EPTViewController.m
//  EPTerrain
//
//  Created by Chris Cieslak on 5/14/14.
//  Copyright (c) 2014 Electropuf. All rights reserved.
//

#import "EPTViewController.h"
#import "EPTTerrainGenerator.h"
@interface EPTViewController ()

@property (nonatomic, strong) EPTTerrainGenerator *generator;

@end

@implementation EPTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.generator = [[EPTTerrainGenerator alloc] initWithDetailLevel:10];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self generateMap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)regenerateTouched:(id)sender {
    [self generateMap];
}

- (IBAction)roughnessChanged:(id)sender {
    self.generator.roughness = [(UISlider *)sender value];
    [self.spinner startAnimating];
    [self generateMap];
    
}

- (void)generateMap {
    [self.spinner startAnimating];
    self.imageView.image = nil;
    __weak EPTTerrainGenerator *weakGenerator = self.generator;
    CGSize size = self.imageView.bounds.size;
    [self.generator generateTerrainMapWithCompletionBlock:^{
        [weakGenerator terrainImageWithSize:size completionBlock:^(UIImage *image) {
            [self.spinner stopAnimating];
            self.imageView.image = image;
        }];
    }];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.imageView.image = nil;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.spinner startAnimating];
    self.imageView.image = nil;
    CGSize size = self.imageView.bounds.size;
    [self.generator terrainImageWithSize:size completionBlock:^(UIImage *image) {
        [self.spinner stopAnimating];
        self.imageView.image = image;
    }];
}
@end
