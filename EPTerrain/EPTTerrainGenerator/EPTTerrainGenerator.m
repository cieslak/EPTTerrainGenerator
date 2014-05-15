//
//  EPTTerrainGenerator.m
//  EPTerrain
//
//  Created by Chris Cieslak on 5/14/14.
//  Copyright (c) 2014 Electropuf. All rights reserved.
//

#import "EPTTerrainGenerator.h"
#include "generatemap.h"
#import <time.h>
@interface EPTTerrainGenerator ()

@property (nonatomic, assign) CGFloat *map;
@property (nonatomic, assign) NSInteger detail;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, readonly) NSInteger max;

@end

static CGColorSpaceRef _colorSpace;

@implementation EPTTerrainGenerator

#pragma mark - Init / dealloc

- (instancetype)initWithDetailLevel:(NSInteger)detail {
    self = [super init];
    
    if (self) {
        _detail = detail;
        _size = pow(2, detail) + 1;
        _map = malloc(sizeof(CGFloat) * _size * _size);
        _roughness = .7f;
        _waterColor = [UIColor colorWithRed:.2f green:.59f blue:.78f alpha:.15];
        _colorSpace = CGColorSpaceCreateDeviceGray();
        srand48(time(0));
    }
    
    return self;
}

- (void)dealloc {
    free(_map);
    CGColorSpaceRelease(_colorSpace);
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

CGColorRef grayColor(CGFloat x, CGFloat y, CGFloat slope, CGFloat max) {
    CGFloat gray;
    if (ceilf(x) == max || ceilf(y) == max) {
        gray = 0.0f;
    } else {
        gray = ((slope * 50) + 128) / 255.0f;
    }
    CGFloat components[2] = {gray, 1.0f};
    CGColorRef color = CGColorCreate(_colorSpace, components);
    return color;
}


- (void)terrainImageWithSize:(CGSize)imageSize completionBlock:(void(^)(UIImage *image))completionBlock {
    void (^blockCopy)(UIImage *image) = [completionBlock copy];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
#if EP_TIME_PROFILE
        clock_t start, end;
        double cpu_time_used;
        start = clock();
#endif
        UIGraphicsBeginImageContextWithOptions(imageSize, YES, [[UIScreen mainScreen] scale]);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        UIImage *image = nil;
        if (ctx) {
            CGFloat mapSize = self.size;
            CGFloat waterLevel = mapSize * .3f;
            CGRect bounds = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
            for (NSInteger x = 0; x < mapSize; x++) {
                for (NSInteger y = 0; y < mapSize; y++) {
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
                    CGRect rect = CGRectFromTopBottom(top, bottom);
                    if (CGRectIntersectsRect(bounds, rect) && !CGRectIsEmpty(rect)) {
                        CGColorRef color = grayColor(x, y, slope, self.max);
                        CGContextSetFillColorWithColor(ctx, color);
                        CGContextFillRect(ctx, rect);
                        CGColorRelease(color);
                        //NSLog(@"drew rect at %@", NSStringFromCGRect(rect));
                    }
                    rect = CGRectFromTopBottom(water, bottom);
                    if (CGRectIntersectsRect(bounds, rect) && !CGRectIsEmpty(rect)) {
                        [_waterColor set];
                        CGContextFillRect(ctx, rect);
                        //NSLog(@"drew water rect at %@", NSStringFromCGRect(rect));
                    }
                }
            }
            
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
#if EP_TIME_PROFILE
        end = clock();
        cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
        printf("image generated in %fs\n", cpu_time_used);
#endif
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
    _waterColor = waterColor ?: [UIColor blueColor];
}

@end
