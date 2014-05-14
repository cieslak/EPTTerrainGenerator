//
//  generatemap.h
//  EPTerrain
//
//  Created by Chris Cieslak on 5/14/14.
//  Copyright (c) 2014 Electropuf. All rights reserved.
//

#ifndef EPTerrain_generatemap_h
#define EPTerrain_generatemap_h

void generatemap(CGFloat *map, NSInteger max, NSInteger size, CGFloat roughness);
void printmap();
CGFloat mapvalue(NSInteger x, NSInteger y);

#endif
