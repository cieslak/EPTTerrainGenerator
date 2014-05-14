//
//  generatemap.c
//  EPTerrain
//
//  Created by Chris Cieslak on 5/14/14.
//  Copyright (c) 2014 Electropuf. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <CoreGraphics/CoreGraphics.h>
#include <objc/NSObjCRuntime.h>
#include <time.h>

NSInteger _max;
NSInteger _size;
CGFloat *_map;
CGFloat _roughness;

CGFloat mapvalue(NSInteger x, NSInteger y) {
    if (x < 0 || x > _max || y < 0 || y > _max) {
        return nanf("");
    }
    return _map[x + _size * y];
}

void setmapvalue(NSInteger x, NSInteger y, CGFloat value) {
    _map[x + _size * y] = value;
}

CGFloat average(CGFloat v1, CGFloat v2, CGFloat v3, CGFloat v4) {
    NSInteger ctr = 0;
    CGFloat total = 0;
    CGFloat values[4] = {v1, v2, v3, v4};
    for (NSInteger i = 0; i < 4; i++) {
        CGFloat val = values[i];
        if (!isnan(val)) {
            ctr++;
            total += val;
        }
    }
    return total / ctr;
}

void square(NSInteger x, NSInteger y, NSInteger size, CGFloat offset) {
    CGFloat ul, ur, ll, lr;
    ul = mapvalue(x - size, y - size);   // upper left
    ur = mapvalue(x + size, y - size);   // upper right
    lr = mapvalue(x + size, y + size);   // lower right
    ll = mapvalue(x - size, y + size);   // lower left
    
    CGFloat avg = average(ul, ll, ur, lr);
    setmapvalue(x, y, avg + offset);
}

void diamond(NSInteger x, NSInteger y, NSInteger size, CGFloat offset) {
    CGFloat t, r, b, l;
    t = mapvalue(x, y - size);   // top
    r = mapvalue(x + size, y);   // right
    b = mapvalue(x, y + size);   // bottom
    l = mapvalue(x - size, y);   // left
    
    CGFloat avg = average(t, r, b, l);
    setmapvalue(x, y, avg + offset);
}

void divide(NSInteger size) {
    
    CGFloat x, y;
    CGFloat half = size / 2;
    CGFloat scale = _roughness * size;
    if (half < 1) {
        return;
    }
    for (y = half; y < _max; y += size) {
        for (x = half; x < _max; x += size) {
            square(x, y, half, drand48() * scale * 2 - scale);
        }
    }
    for (y = 0; y <= _max; y += half) {
        for (x = (NSInteger)(y + half) % size; x <= _max; x += size) {
            diamond(x, y, half, drand48() * scale * 2 - scale);
        }
    }
    divide(size / 2);
    
}

void generatemap(CGFloat *map, NSInteger max, NSInteger size, CGFloat roughness) {
#if EP_TIME_PROFILE
    clock_t start, end;
    double cpu_time_used;
    start = clock();
#endif
    _map = map;
    _max = max;
    _size = size;
    _roughness = roughness;
    
    setmapvalue(0, 0, _max);
    setmapvalue(_max, 0, _max / 2);
    setmapvalue(_max, _max, 0);
    setmapvalue(0, _max, _max / 2);
    
    divide(_size);
#if EP_TIME_PROFILE
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
    printf("map generated in %fs\n", cpu_time_used);
#endif
}

void printmap() {
    for (NSInteger y = 0; y < _size; y++) {
        for (NSInteger x = 0; x < _size; x ++) {
            printf("%f ", mapvalue(x, y));
        }
        printf("\n");
    }
}
