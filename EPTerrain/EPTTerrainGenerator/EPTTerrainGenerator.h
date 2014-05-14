//
//  EPTTerrainGenerator.h
//  EPTerrain
//
//  Created by Chris Cieslak on 5/14/14.
//  Copyright (c) 2014 Electropuf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPTTerrainGenerator : NSObject

- (instancetype)initWithDetailLevel:(NSInteger)detail;

- (void)generateTerrainMapWithCompletionBlock:(void (^)(void))completionBlock;
- (void)terrainImageWithSize:(CGSize)size completionBlock:(void(^)(UIImage *image))completionBlock;

@property (nonatomic, readonly) CGFloat *map;
@property (nonatomic, readonly) NSInteger detail;
@property (nonatomic, assign) CGFloat roughness;
@property (nonatomic, strong) UIColor *waterColor;

@end
