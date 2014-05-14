//
//  EPTTerrainGenerator.m
//  EPTerrain
//
//  Created by Chris Cieslak on 5/14/14.
//  Copyright (c) 2014 Electropuf. All rights reserved.
//

#import "EPTTerrainGenerator.h"
#include "generatemap.h"
@interface EPTTerrainGenerator ()

@property (nonatomic, assign) CGFloat *map;
@property (nonatomic, assign) NSInteger detail;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, readonly) NSInteger max;

@end

@implementation EPTTerrainGenerator

#pragma mark - Init / dealloc

- (instancetype)initWithDetailLevel:(NSInteger)detail {
    self = [super init];
    
    if (self) {
        _detail = detail;
        _size = pow(2, detail) + 1;
        _map = malloc(sizeof(CGFloat) * _size * _size);
        _roughness = .7f;
        _waterColor = [UIColor blueColor];
        srand48(time(0));
    }
    
    return self;
}

- (void)dealloc {
    free(_map);
}

#pragma mark - Generate terrain map

- (void)generateTerrainMapWithCompletionBlock:(void (^)(void))completionBlock {
    void (^blockCopy)() = [completionBlock copy];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        generatemap(self.map, self.max, self.size, self.roughness);
        if (blockCopy) {
            dispatch_async(dispatch_get_main_queue(), ^{
                blockCopy();
            });
        }
    });
}

#pragma mark - Generate terrain image

static inline CGPoint iso (NSInteger x, NSInteger y, NSInteger size) {
    return CGPointMake(.5f * (size + x - y), .5f * (x + y));
}

static inline CGRect CGRectFromTopBottom (CGPoint top, CGPoint bottom) {
    if (bottom.y < top.y) {
        return CGRectZero;
    }
    return CGRectMake(top.x, top.y, bottom.x - top.x, bottom.y - top.y);
}

CGPoint project (CGFloat flatX, CGFloat flatY, CGFloat flatZ, NSInteger mapSize, CGSize imageSize) {
    CGPoint point = iso(flatX, flatY, mapSize);
    CGFloat x0, y0, z, x, y;
    x0 = imageSize.width * .5f;
    y0 = imageSize.height * .5f;
    z = mapSize * .5f - flatZ + point.y * .75;
    x = (point.x - mapSize * .5f) * 6;
    y = (mapSize - point.y) * .005 + 1;
    return CGPointMake(x0 + x / y, y0 + z / y);
}

- (UIColor *)colorForX:(CGFloat)x y:(CGFloat)y slope:(CGFloat)slope {
    if (ceilf(x) == self.max || ceilf(y) == self.max) {
        return [UIColor blackColor];
    }
    CGFloat gray = (slope * 50) + 128;
    return [UIColor colorWithWhite:gray/255.f alpha:1.0f];
}


- (void)terrainImageWithSize:(CGSize)imageSize completionBlock:(void(^)(UIImage *image))completionBlock {
    void (^blockCopy)(UIImage *image) = [completionBlock copy];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        UIGraphicsBeginImageContextWithOptions(imageSize, YES, [[UIScreen mainScreen] scale]);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        UIImage *image = nil;
        if (ctx) {
            CGFloat mapSize = self.size;
            CGFloat waterLevel = mapSize * .3f;
            for (NSInteger x = 0; x < mapSize; x++) {
                for (NSInteger y = 0; y < mapSize; y ++) {
                    CGFloat value = mapvalue(x, y);
                    if (isnan(value)) {
                        value = -1;
                    }
                    CGPoint top = project(x, y, value, mapSize, imageSize);
                    CGPoint bottom = project(x + 1, y, 0, mapSize, imageSize);
                    CGPoint water = project(x, y, waterLevel, mapSize, imageSize);
                    CGFloat slope = mapvalue(x + 1, y);
                    if (isnan(slope)) {
                        slope = -1;
                    }
                    slope -= value;
                    UIColor *color = [self colorForX:x y:y slope:slope];
                    CGRect rect = CGRectFromTopBottom(top, bottom);
                    [color set];
                    CGContextFillRect(ctx, rect);
                    rect = CGRectFromTopBottom(water, bottom);
                    [self.waterColor set];
                    CGContextFillRect(ctx, rect);
                }
            }
            
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        if (blockCopy) {
            dispatch_async(dispatch_get_main_queue(), ^{
                blockCopy(image);
            });
        }
    });
}


#pragma mark - Properties

- (NSInteger)max {
    return self.size - 1;
}

- (void)setWaterColor:(UIColor *)waterColor {
    _waterColor = _waterColor ?: [UIColor blueColor];
}

@end
