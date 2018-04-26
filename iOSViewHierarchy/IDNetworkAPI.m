//
//  IDNetworkAPI.m
//  iDebugger
//
//  Created by Isaac on 2018/4/26.
//

#import "IDNetworkAPI.h"
#import "GCDWebServer.h"
#import "GCDWebServerFileResponse.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"
#import "NEHTTPModelManager.h"

@implementation IDNetworkAPI

+ (void)registerAPI: (GCDWebServer *)server
{
    [server addHandlerForMethod: @"GET"
                           path: @"/network/list"
                   requestClass: [GCDWebServerDataRequest class]
                   processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request)
                                  {
                                      NSArray *result = [[[[NEHTTPModelManager defaultManager] allobjects] reverseObjectEnumerator] allObjects];
                                      return [GCDWebServerDataResponse responseWithJSONObject: result];
                                  })];
}

@end
