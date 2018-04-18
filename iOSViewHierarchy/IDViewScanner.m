//
//  IDViewScanner.m
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import "IDViewScanner.h"
#import "IDScanner.h"
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
                               @{@"name": @"alpha", @"type": @"Td", @"ext": @{ @"min": @0, @"max": @1}},
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
                               @{@"name": @"opacity", @"type": @"Td", @"ext": @{ @"min": @0, @"max": @1}},
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
        
        propertyDescription[@"name"] = propertyName;
        if (looper[@"ext"]) {
            propertyDescription[@"ext"] = looper[@"ext"];
        }
        
        NSArray *attributes = [propertyType componentsSeparatedByString: @","];
        NSString *typeAttribute = attributes[0];
        NSString *type = [typeAttribute substringFromIndex: 1];
        const char *rawPropertyType = [type UTF8String];
        
        BOOL readValue = NO;
        BOOL checkOnlyIfNil = NO;
        
        if (strcmp(rawPropertyType, @encode(float)) == 0) {
            propertyDescription[@"type"] = @"float";
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(double)) == 0) {
            propertyDescription[@"type"] = @"double";
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(int)) == 0) {
            propertyDescription[@"type"] = @"int";
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(long)) == 0) {
            propertyDescription[@"type"] = @"long";
            readValue = YES;
        } else if (strcmp(rawPropertyType, @encode(BOOL)) == 0) {
            propertyDescription[@"type"] = @"BOOL";
            readValue = NO;
            NSNumber *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            propertyDescription[@"value"] = propertyValue.boolValue ? @"YES" : @"NO";
        } else if (strcmp(rawPropertyType, @encode(char)) == 0) {
            propertyDescription[@"type"] = @"char";
        } else if ( type && ( [type hasPrefix:@"{CGRect="] ) ) {
            readValue = NO;
            NSValue *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            
            propertyDescription[@"value"] = NSStringFromCGRect(propertyValue.CGRectValue);
            propertyDescription[@"type"] = @"CGRect";
        } else if ( type && ( [type hasPrefix:@"{CGPoint="] ) ) {
            readValue = NO;
            NSValue *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            propertyDescription[@"value"] = NSStringFromCGPoint(propertyValue.CGPointValue);
            propertyDescription[@"type"] = @"CGPoint";
        } else if ( type && ( [type hasPrefix:@"{CGSize="] ) ) {
            readValue = NO;
            NSValue *propertyValue;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            propertyDescription[@"value"] =  NSStringFromCGSize(propertyValue.CGSizeValue);
            propertyDescription[@"type"] = @"CGSize";
        } else if ( type && ( [type hasPrefix:@"{CGAffineTransform="] ) ) {
            readValue = NO;
            CGAffineTransform *propertyValue;
            @try {
                propertyValue = (__bridge CGAffineTransform*)[obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            propertyDescription[@"value"] = NSStringFromCGAffineTransform2(*propertyValue);
            propertyDescription[@"type"] = @"CGAffineTransform";
        } else if ( type && ( [type hasPrefix:@"{CATransform3D="] ) ) {
            readValue = NO;
            CATransform3D *propertyValue;
            @try {
                propertyValue = (__bridge CATransform3D*)[obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            
            propertyDescription[@"value"] = NSStringFromCATransform3D(*propertyValue);
            propertyDescription[@"type"] = @"CATransform3D";
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
                
                propertyDescription[@"value"] = propertyValue ? UIColorToNSString(propertyValue) : @"nil";
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
                propertyDescription[@"value"] = propertyValue != nil ? @"OBJECT" : @"nil";
            } else {
                propertyDescription[@"value"] = propertyValue != nil ? [NSString stringWithFormat:@"%@", propertyValue] : @"nil";
            }
        }
        [propertiesArray addObject:propertyDescription];
    }
    
    return propertiesArray;
}

@end
