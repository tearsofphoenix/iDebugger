//
//  iDebugger.m
//  iDebugger
//
//  Created by Isaac on 2018/4/16.
//
#import "GCDWebServer.h"
#import "GCDWebServerFileResponse.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"

#import "IDScanner.h"
#import "IDFileScanner.h"
#import "IDViewScanner.h"
#import "IDViewUpdator.h"
#import "iDebugger.h"
#import "SystemServices.h"
#import "CRToastConfig.h"
#import "CRToastManager.h"

#import <objc/runtime.h>

static iDebugger *kDebugger = nil;

@interface iDebugger()

@property (nonatomic, strong) GCDWebServer *server;

@end

@implementation iDebugger

+ (instancetype)instance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kDebugger = [[self alloc] init];
    });
    return kDebugger;
}

- (id)init
{
    if ((self = [super init]))
    {
        _server = [[GCDWebServer alloc] init];
        [_server addHandlerForMethod: @"POST"
                                path: @"/connect"
                        requestClass: [GCDWebServerRequest class]
                        processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request)
                                       {
                                           id response = [GCDWebServerDataResponse responseWithJSONObject: (@{@"code": @1000})];
                                           return response;
                                       })];
        [IDViewScanner registerAPI: _server];
        [IDFileScanner registerAPI: _server];
        
        [_server addHandlerForMethod: @"GET"
                                path: @"/system/info"
                        requestClass: [GCDWebServerRequest class]
                   asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                       {
                                           id result = [[SystemServices sharedServices] allSystemInformation];
                                           NSLog(@"%@", result);
                                           id response = [GCDWebServerDataResponse responseWithJSONObject: result];
                                           completionBlock(response);
                                       })];
    }
    return self;
}

static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    return attributes;
}

- (void)start
{
    Class viewClass = [UIView class];
    uint outCount = 0;
    objc_property_t *properties = class_copyPropertyList(viewClass, &outCount);
    for (int i = 0; i < outCount; ++i) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithCString:propName
                                                        encoding:[NSString defaultCStringEncoding]];
            NSString *propertyType = [NSString stringWithCString:propType
                                                        encoding:[NSString defaultCStringEncoding]];
            NSLog(@"%@ %@", propertyName, propertyType);
        }
    }
    uint16_t port = 9449;
    [_server startWithPort: port
               bonjourName: nil];
    NSString *ip = [[SystemServices sharedServices] wiFiIPAddress];
    NSString *text = [NSString stringWithFormat: @"debugger run at http://%@:%d", ip, port];
    NSDictionary *options = @{
                              kCRToastTextKey : text,
                              kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                              kCRToastBackgroundColorKey : [UIColor redColor],
                              kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                              kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeGravity),
                              kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionLeft),
                              kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionRight)
                              };
    [CRToastManager showNotificationWithOptions: options
                                completionBlock: nil];
}

@end
