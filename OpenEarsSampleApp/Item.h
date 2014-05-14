//
//  Item.h
//  OpenEarsSampleApp
//
//  Created by Vasanth Sundaralingam on 5/13/14.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Item : NSObject
{
   NSString *upc;
   NSString *price;
   UIImage *image;
}

@property(nonatomic, retain) NSString *upc;
@property(nonatomic, retain) NSString *price;
@property(nonatomic, retain) UIImage *image;


@end
