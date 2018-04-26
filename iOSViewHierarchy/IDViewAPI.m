//
//  IDViewScanner.m
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import "IDViewAPI.h"
#import "IDScanner.h"
#import "IDViewUpdator.h"

#import "GCDWebServer.h"
#import "GCDWebServerFileResponse.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"

#import <CoreGraphics/CoreGraphics.h>

static NSMutableDictionary *kMap = nil;

@implementation IDViewAPI

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
                               @{@"name": @"alpha", @"type": @"Td", @"ext": @{ @"min": @0, @"max": @1, @"scale": @100}},
                               @{@"name": @"hidden", @"type": @"TB"},
                               @{@"name": @"backgroundColor", @"type": @"T@\"UIColor\""},
                               @{@"name": @"opaque", @"type": @"TB"},
                               @{@"name": @"clearsContextBeforeDrawing", @"type": @"TB"},
                               @{@"name": @"tintColor", @"type": @"T@\"UIColor\""}
                               ])
                   forName: @"UIViewRendering"];
    
    [self addPropertyArray: (@[
                               @{@"name": @"maskedCorners", @"type": @"TQ"},
                               @{@"name": @"cornerRadius", @"type": @"Td"},
                               @{@"name": @"borderWidth", @"type": @"Td"},
                               @{@"name": @"borderColor", @"type": @"T^{CGColor=}"},
                               @{@"name": @"opacity", @"type": @"Td", @"ext": @{ @"min": @0, @"max": @1, @"scale": @100}},
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
            NSString *typeClassName = [type substringWithRange: NSMakeRange(2, type.length - 3)];
            propertyDescription[@"type"] = typeClassName;
            if ([typeClassName isEqualToString: NSStringFromClass([UIColor class])]) {
                readValue = NO;
                id propertyValue;
                @try {
                    propertyValue = [obj valueForKey:propertyName];
                }
                @catch (NSException *exception) {
                    propertyValue = nil;
                }
                
                propertyDescription[@"value"] = UIColorToNSString(propertyValue);
            }
            if ([typeClassName isEqualToString:[[NSString class] description]]) {
                checkOnlyIfNil = NO;
            }
            if ([typeClassName isEqualToString:[[UIFont class] description]]) {
                checkOnlyIfNil = NO;
            }
        } else if ([type hasPrefix: @"^{CGColor=}"]) {
            
            propertyDescription[@"type"] = @"UIColor";
            readValue = NO;
            id propertyValue = nil;
            @try {
                propertyValue = [obj valueForKey:propertyName];
            }
            @catch (NSException *exception) {
                propertyValue = nil;
            }
            propertyDescription[@"value"] = CGColorToNSString((__bridge CGColorRef)propertyValue);
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
                propertyDescription[@"value"] = propertyValue != nil ? @"OBJECT" : @"0";
            } else {
                propertyDescription[@"value"] = propertyValue != nil ? [NSString stringWithFormat:@"%@", propertyValue] : @"0";
            }
        }
        [propertiesArray addObject:propertyDescription];
    }
    
    return propertiesArray;
}

+ (void)registerAPI: (GCDWebServer *)server
{
    
    [server addHandlerForMethod: @"GET"
                           path: @"/view/snapshot"
                   requestClass: [GCDWebServerRequest class]
              asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                  {
                                      NSArray *hierarchyDict = [ IDScanner hierarchySnapshot];
                                      CGRect screenRect = [[UIScreen mainScreen] bounds];
                                      NSDictionary *responseDic = (@{
                                                                     @"windows": hierarchyDict,
                                                                     @"screen_w": @(screenRect.size.width),
                                                                     @"screen_h": @(screenRect.size.height),
                                                                     @"version": @"0.0.1"
                                                                     });
                                      
                                      GCDWebServerResponse *response = [GCDWebServerDataResponse responseWithJSONObject: responseDic];
                                      completionBlock(response);
                                  })];
    [server addHandlerForMethod: @"POST"
                           path: @"/view/update"
                   requestClass: [GCDWebServerDataRequest class]
              asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                  {
                                      GCDWebServerDataRequest *req = request;
                                      NSDictionary *body = [req jsonObject];
                                      NSInteger viewID = [body[@"target"] integerValue];
                                      NSDictionary *property = body[@"property"];
                                      [IDViewUpdator updateValue: body[@"value"]
                                                        property: property
                                                         forView: viewID
                                                      completion: (^
                                                                   {
                                                                       NSDictionary *responseDic = (@{ @"code": @1000 });
                                                                       GCDWebServerResponse *response = [GCDWebServerDataResponse responseWithJSONObject: responseDic];
                                                                       completionBlock(response);
                                                                   })];
                                  })];
    __weak __typeof__(self) weakSelf = self;
    [server addHandlerForMethod: @"GET"
                           path: @"/preview"
                   requestClass: [GCDWebServerRequest class]
              asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                  {
                                      dispatch_async(dispatch_get_main_queue(),
                                                     (^
                                                      {
                                                          [weakSelf handlePreview: request
                                                                         callback: completionBlock];
                                                      }));
                                  })];
    
}


#pragma mark -
+ (void)handlePreview: (__kindof GCDWebServerRequest * _Nonnull)request
             callback: (GCDWebServerCompletionBlock  _Nonnull)completionBlock
{
    NSString *queryID = [request query][@"id"];
    if (queryID)
    {
        long id = [queryID longLongValue];
        UIView *view = [IDScanner findViewById: id];
        if (view)
        {
            UIGraphicsBeginImageContext(view.bounds.size);
            
            [view.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            
            NSData *pngData = UIImagePNGRepresentation(image);
            UIGraphicsEndImageContext();
            
            GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData: pngData
                                                                                contentType: @"image/*"];
            completionBlock(response);
        } else {
            completionBlock(nil);
        }
    } else {
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        UIGraphicsBeginImageContext(CGSizeMake(screenWidth, screenHeight));
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            [w.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        NSData *scaledData = UIImagePNGRepresentation(image);
        UIGraphicsEndImageContext();
        
        GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData: scaledData
                                                                            contentType: @"image/*"];
        completionBlock(response);
    }
}

@end

