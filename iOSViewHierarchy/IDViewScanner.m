//
//  IDViewScanner.m
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import "IDViewScanner.h"
#import "HVHierarchyScanner.h"
#import <CoreGraphics/CoreGraphics.h>

static NSMutableDictionary *kMap = nil;

@implementation IDViewScanner

+ (void)load
{
    kMap = [NSMutableDictionary dictionary];
    
    [self addPropertyArray: (@[
                               @{@"name": @"bounds", @"type": @"T{CGRect={CGPoint=dd}{CGSize=dd}},R,N"},
                               @{@"name": @"center", @"type": @"T{CGPoint=dd},N"},
                               @{@"name": @"transform", @"type": @"T{CGAffineTransform=dddddd},N"},
                               @{@"name": @"contentScaleFactor", @"type": @"Tf"},
                               @{@"name": @"autoresizesSubviews", @"type": @"TB"},
                               //              @{@"name": @"autoresizingMask", @"type": @"T"}
                               ])
                   forName: @"UIViewGeometry"];
    
    [self addPropertyArray: (@[
                               @{@"name": @"clipToBounds", @"type": @"TB"},
                               @{@"name": @"alpha", @"type": @"Td"},
                               @{@"name": @"hidden", @"type": @"TB"},
                               @{@"name": @"backgroundColor", @"type": @"T^{CGColor=}"},
                               @{@"name": @"opaque", @"type": @"TB"},
                               @{@"name": @"clearsContextBeforeDrawing", @"type": @"TB"},
                               @{@"name": @"hidden", @"type": @"TB"},
                               @{@"name": @"tintColor", @"type": @"T^{CGColor=}"}                        
                               ])
                   forName: @"UIViewRendering"];
    
    [self addPropertyArray: (@[
                               @{@"name": @"maskedCorners", @"type": @"TQ"},
                               @{@"name": @"cornerRadius", @"type": @"Td"},
                               @{@"name": @"borderWidth", @"type": @"Td"},
                               @{@"name": @"borderColor", @"type": @"T^{CGColor=}"},
                               @{@"name": @"opacity", @"type": @"Td"},
                               @{@"name": @"shadowColor", @"type": @"T^{CGColor=}"},
                               @{@"name": @"shadowOpacity", @"type": @"Td"},
                               @{@"name": @"shadowRadius", @"type": @"Td"},
                               ])
                   forName: @"CALayer"];
}

+ (void)addPropertyArray: (NSArray *)array
                 forName: (NSString *)name
{
    kMap[name] =  array;
}

+ (void)removePropertyForName: (NSString *)name
{
    [kMap removeObjectForKey: name];
}

+ (NSArray *)scanPropertyOfObject: (id)object
{
    NSMutableArray *result = [NSMutableArray array];
    [kMap enumerateKeysAndObjectsUsingBlock: (^(id  _Nonnull key, id  _Nonnull properties, BOOL * _Nonnull stop)
                                              {
                                                  NSArray *props = [self scanProperties: properties
                                                                                 object: object];
                                                  [result addObject: @{
                                                                       @"name": key,
                                                                       @"props": props
                                                                       }];
                                              })];
    return result;
}

+ (NSArray *)scanProperties: (NSArray *)properties
                     object: (id) obj
{
    NSMutableArray *propertiesArray = [NSMutableArray array];
    for (int i = 0; i < [properties count]; i++)
    {
        NSDictionary *looper = properties[i];
        NSMutableDictionary *propertyDescription = [[NSMutableDictionary alloc] initWithCapacity:2];
        NSString *propertyName = looper[@"name"];
        NSString *propertyType = looper[@"type"];
        [propertyDescription setValue:propertyName forKey:@"name"];
        
        NSArray *attributes = [propertyType componentsSeparatedByString:@","];
        NSString *typeAttribute = attributes[0];
        NSString *type = [typeAttribute substringFromIndex: 1];
        const char *rawPropertyType = [type UTF8String];
        
        BOOL readValue = NO;
        BOOL checkOnlyIfNil = NO;
        
        if (strcmp(rawPropertyType, @encode(float)) == 0) {
            [propertyDescription setValue:@"float" forKey:@"type"];
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(double)) == 0) {
            [propertyDescription setValue:@"double" forKey:@"type"];
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(int)) == 0) {
            [propertyDescription setValue:@"int" forKey:@"type"];
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(long)) == 0) {
            [propertyDescription setValue:@"long" forKey:@"type"];
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(BOOL)) == 0) {
            [propertyDescription setValue:@"BOOL" forKey:@"type"];
            readValue = NO;
            NSNumber *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            [propertyDescription setValue:(propertyValue.boolValue ? @"YES" : @"NO") forKey:@"value"];
        } else if (strcmp(rawPropertyType, @encode(char)) == 0) {
            [propertyDescription setValue:@"char" forKey:@"type"];
        } else if ( type && ( [type hasPrefix:@"{CGRect="] ) ) {
            readValue = NO;
            NSValue *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            [propertyDescription setValue:[NSString stringWithFormat:@"%@", NSStringFromCGRect(propertyValue.CGRectValue)] forKey:@"value"];
            [propertyDescription setValue:@"CGRect" forKey:@"type"];
        } else if ( type && ( [type hasPrefix:@"{CGPoint="] ) ) {
            readValue = NO;
            NSValue *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            [propertyDescription setValue:[NSString stringWithFormat:@"%@", NSStringFromCGPoint(propertyValue.CGPointValue)] forKey:@"value"];
            [propertyDescription setValue:@"CGPoint" forKey:@"type"];
        } else if ( type && ( [type hasPrefix:@"{CGSize="] ) ) {
            readValue = NO;
            NSValue *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            [propertyDescription setValue:[NSString stringWithFormat:@"%@", NSStringFromCGSize(propertyValue.CGSizeValue)] forKey:@"value"];
            [propertyDescription setValue:@"CGSize" forKey:@"type"];
        } else if ( type && ( [type hasPrefix:@"{CGAffineTransform="] ) ) {
            readValue = NO;
            CGAffineTransform *propertyValue;
            @try {
                propertyValue = (__bridge CGAffineTransform*)[obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            [propertyDescription setValue:[NSString stringWithFormat:@"%@", NSStringFromCGAffineTransform2(*propertyValue)] forKey:@"value"];
            [propertyDescription setValue:@"CGAffineTransform" forKey:@"type"];
        } else if ( type && ( [type hasPrefix:@"{CATransform3D="] ) ) {
            readValue = NO;
            CATransform3D *propertyValue;
            @try {
                propertyValue = (__bridge CATransform3D*)[obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            [propertyDescription setValue:[NSString stringWithFormat:@"%@", NSStringFromCATransform3D(*propertyValue)] forKey:@"value"];
            [propertyDescription setValue:@"CATransform3D" forKey:@"type"];
        } else if (type && [type hasPrefix:@"@"] && type.length > 3) {
            readValue = YES;
            checkOnlyIfNil = YES;
            NSString *typeClassName = [type substringWithRange:NSMakeRange(2, type.length - 3)];
            [propertyDescription setValue:typeClassName forKey:@"type"];
            if ([typeClassName isEqualToString:[[UIColor class] description]]) {
                readValue = NO;
                id propertyValue;
                @try {
                    propertyValue = [obj valueForKey:propertyName];
                }
                @catch (NSException *exception) {
                    propertyValue = nil;
                }
                
                [propertyDescription setValue:(propertyValue ? UIColorToNSString(propertyValue) : @"nil") forKey:@"value"];
            }
            if ([typeClassName isEqualToString:[[NSString class] description]]) {
                checkOnlyIfNil = NO;
            }
            if ([typeClassName isEqualToString:[[UIFont class] description]]) {
                checkOnlyIfNil = NO;
            }
        } else if ([type hasPrefix: @"^{CGColor=}"]) {
            
//            propertyDescription[@"type"] = @"UIColor";
//            readValue = NO;
//            id propertyValue = nil;
//            @try {
//                propertyValue = [obj valueForKey:propertyName];
//            }
//            @catch (NSException *exception) {
//                propertyValue = nil;
//            }
//            propertyDescription[@"value"] = (propertyValue ? CGColorToNSString((__bridge CGColorRef)propertyValue) : @"nil");
        } else {
            [propertyDescription setValue:propertyType forKey:@"type"];
        }
        if (readValue) {
            id propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            } @catch (NSException *exception) {
                propertyValue = nil;
            }
            if (checkOnlyIfNil) {
                [propertyDescription setValue:(propertyValue != nil ? @"OBJECT" : @"nil") forKey:@"value"];
            } else {
                [propertyDescription setValue:(propertyValue != nil ? [NSString stringWithFormat:@"%@", propertyValue] : @"nil") forKey:@"value"];
            }
        }
        [propertiesArray addObject:propertyDescription];
    }
    
    return propertiesArray;
}

@end

