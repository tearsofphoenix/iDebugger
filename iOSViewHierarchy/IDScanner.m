//
//   IDScanner.m
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import <objc/runtime.h>
#import <math.h>
#import <QuartzCore/QuartzCore.h>
#import "IDScanner.h"
#import "IDViewScanner.h"

static NSArray *kPropertyBlackList = nil;
static NSArray *kClassIgnoreList = nil;

@implementation  IDScanner

+ (void)load
{
    kPropertyBlackList = @[@"selectedTextRange"];
    kClassIgnoreList = @[@"UIWindow"];
}

CGFloat handleNotFinite(CGFloat value)
{
    if (!isfinite(value)) {
        return 1;
    }
    return value;
}

+ (UIView *)recursiveSearchForView:(long)_id parent:(UIView *)parent
{
    if ((__bridge void *)parent == (void *)_id) {
        return parent;
    }
    for (UIView *v in parent.subviews) {
        UIView *result = [ IDScanner recursiveSearchForView:_id parent:v];
        if (result) {
            return result;
        }
    }
    return nil;
}

+ (UIView *)findViewById:(long)_id
{
    UIApplication *app = [UIApplication sharedApplication];
    if (app) {
        for (UIView *v in app.windows) {
            UIView *result = [ IDScanner recursiveSearchForView:_id parent:v];
            if (result) {
                return result;
            }
        }
    }
    return nil;
}

NSString *UIColorToNSString(UIColor *color)
{
    return CGColorToNSString([color CGColor]);
}

NSString *CGColorToNSString(CGColorRef color)
{
    if (color) {
        CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
        CGColorSpaceModel model = CGColorSpaceGetModel(colorSpace);
        
        NSString *prefix = @"A???";
        switch (model) {
            case kCGColorSpaceModelCMYK:
                prefix = @"CMYKA";
                break;
            case kCGColorSpaceModelDeviceN:
                prefix = @"DeviceNA";
                break;
            case kCGColorSpaceModelIndexed:
                prefix = @"IndexedA";
                break;
            case kCGColorSpaceModelLab:
                prefix = @"LabA";
                break;
            case kCGColorSpaceModelMonochrome:
                prefix = @"MONOA";
                break;
            case kCGColorSpaceModelPattern:
                prefix = @"APattern";
                break;
            case kCGColorSpaceModelRGB:
                prefix = @"RGBA";
                break;
            case kCGColorSpaceModelUnknown:
                prefix = @"A???";
                break;
        }
        size_t n = CGColorGetNumberOfComponents(color);
        const CGFloat *componentsArray = CGColorGetComponents(color);
        
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:n];
        //[array addObject:[NSNumber numberWithInt:(int)(CGColorGetAlpha([color CGColor])*255.0f)]];
        for (size_t i = 0; i < n; ++i) {
            [array addObject:@((int)(componentsArray[i] * 255.0f))];
        }
        NSString *components = [array componentsJoinedByString:@","];
        
        return [NSString stringWithFormat:@"%@(%@)", prefix, components];
    }
    return @"nil";
}

NSString* NSStringFromCGAffineTransform2(CGAffineTransform transform)
{
    return [NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f",
            transform.a,
            transform.b,
            transform.c,
            transform.d,
            transform.tx,
            transform.ty];
}

NSString* NSStringFromCATransform3D(CATransform3D transform)
{
    return [NSString stringWithFormat:@"%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f",
            (transform.m11),
            (transform.m12),
            (transform.m13),
            (transform.m14),
            (transform.m21),
            (transform.m22),
            (transform.m23),
            (transform.m24),
            (transform.m31),
            (transform.m32),
            (transform.m33),
            (transform.m34),
            (transform.m41),
            (transform.m42),
            (transform.m43),
            (transform.m44)
            ];
}

+ (NSDictionary *)recursivePropertiesScan:(UIView *)view
{
    if (view) {
        NSMutableDictionary *viewDescription = [[NSMutableDictionary alloc] initWithCapacity:10];
        // put base properties
        NSString *className = [[view class] description];
        NSString *objectName = view.accessibilityLabel ? [NSString stringWithFormat:@"%@ : %@", view.accessibilityLabel, className] : className;
        [viewDescription setValue:objectName forKey:@"class"];
        [viewDescription setValue:@((long)view) forKey:@"id"];
        
        [viewDescription setValue:NSStringFromCATransform3D(view.layer.transform) forKey:@"layer_transform"];
        [viewDescription setValue: @(handleNotFinite(view.layer.bounds.origin.x)) forKey:@"layer_bounds_x"];
        [viewDescription setValue: @(handleNotFinite(view.layer.bounds.origin.y)) forKey:@"layer_bounds_y"];
        [viewDescription setValue: @(handleNotFinite(view.layer.bounds.size.width)) forKey:@"layer_bounds_w"];
        [viewDescription setValue: @(handleNotFinite(view.layer.bounds.size.height)) forKey:@"layer_bounds_h"];
        [viewDescription setValue: @(handleNotFinite(view.layer.position.x)) forKey:@"layer_position_x"];
        [viewDescription setValue: @(handleNotFinite(view.layer.position.y)) forKey:@"layer_position_y"];
        [viewDescription setValue: @(handleNotFinite(view.layer.anchorPoint.x)) forKey:@"layer_anchor_x"];
        [viewDescription setValue: @(handleNotFinite(view.layer.anchorPoint.y)) forKey:@"layer_anchor_y"];
        
        // put properties from super classes
        NSMutableArray *properties = [[NSMutableArray alloc] initWithCapacity:10];
        
        [properties addObjectsFromArray: [IDViewScanner scanPropertyOfObject: view]];
        
        [viewDescription setValue:properties forKey:@"props"];
        
        NSMutableArray *subViewsArray = [[NSMutableArray alloc] initWithCapacity:10];
        for (UIView *subview in view.subviews) {
            NSDictionary *subviewDictionary = [ IDScanner recursivePropertiesScan:subview];
            if (subviewDictionary) {
                [subViewsArray addObject:subviewDictionary];
            }
        }
        [viewDescription setValue:subViewsArray forKey:@"views"];
        return viewDescription;
    }
    return nil;
}

+ (NSArray *)hierarchySnapshot
{
    UIApplication *app = [UIApplication sharedApplication];
    NSMutableArray *windowViews = [[NSMutableArray alloc] initWithCapacity: 10];
    if (app) {
        dispatch_block_t gatherProperties = ^() {
            for (UIWindow *window in app.windows) {
                NSDictionary* windowDictionary = [ IDScanner recursivePropertiesScan:window];
                [windowDictionary setValue:[NSString stringWithFormat:@"/preview?id=%ld", (long)window] forKey:@"preview"];
                [windowViews addObject:windowDictionary];
            }
        };
        
        //! don't want to lock out our thread
        if ([NSThread mainThread] == [NSThread currentThread]) {
            gatherProperties();
        } else {
            dispatch_sync(dispatch_get_main_queue(), gatherProperties);
        }
    }
    return windowViews;
}

@end
