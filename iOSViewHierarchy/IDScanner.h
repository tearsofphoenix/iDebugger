//
//   IDScanner.h
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

extern CGFloat handleNotFinite(CGFloat value);

extern NSString *UIColorToNSString(UIColor *color);

extern NSString *CGColorToNSString(CGColorRef color);

extern NSString* NSStringFromCATransform3D(CATransform3D transform);

extern NSString* NSStringFromCGAffineTransform2(CGAffineTransform transform);

extern UIColor *IDHexStringToColor(NSString *hexString);

@interface  IDScanner : NSObject

+ (NSDictionary *)recursivePropertiesScan:(UIView *)view;

+ (NSArray *)hierarchySnapshot;

+ (UIView *)findViewById:(long)id;

@end
