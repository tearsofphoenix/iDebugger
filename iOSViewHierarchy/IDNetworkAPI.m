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
#import "NEHTTPModel.h"

static id guardNil(id obj)
{
    return obj ? obj : @"";
}

static NSDictionary *modelToJSON(NEHTTPModel *model)
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"id"] = @([model myID]);
    json[@"startDate"] = [model startDateString];
    json[@"endDate"] = [model endDateString];
    
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    request[@"url"] = [model requestURLString];
    request[@"cachePolicy"] = guardNil([model requestCachePolicy]);
    request[@"timeout"] = @([model requestTimeoutInterval]);
    request[@"method"] = [model requestHTTPMethod];
    request[@"headers"] = guardNil([model requestAllHTTPHeaderFields]);
    request[@"body"] = guardNil([model requestHTTPBody]);
    
    json[@"request"] = request;
    
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    response[@"MIME"] = guardNil([model responseMIMEType]);
    response[@"contentLength"] = guardNil([model responseExpectedContentLength]);
    response[@"encoding"] = guardNil([model responseTextEncodingName]);
    response[@"fileName"] = guardNil([model responseSuggestedFilename]);
    response[@"status"] = @([model responseStatusCode]);
    response[@"headers"] = guardNil([model responseAllHeaderFields]);
    response[@"body"] = guardNil([model receiveJSONData]);
    
    json[@"response"] = response;
    
    return json;
}

@implementation IDNetworkAPI

+ (void)registerAPI: (GCDWebServer *)server
{
    [NEHTTPEye setEnabled: YES];
    [server addHandlerForMethod: @"GET"
                           path: @"/network/list"
                   requestClass: [GCDWebServerDataRequest class]
                   processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request)
                                  {
                                      NSArray *all = [[[[NEHTTPModelManager defaultManager] allobjects] reverseObjectEnumerator] allObjects];
                                      NSMutableArray *result = [NSMutableArray arrayWithCapacity: [all count]];
                                      [all enumerateObjectsUsingBlock: (^(NEHTTPModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
                                                                        {
                                                                            id json = modelToJSON(obj);
                                                                            NSLog(@"%@ %@", obj, json);
                                                                            if (json) {
                                                                                [result addObject: json];
                                                                            }
                                                                        })];
                                      return [GCDWebServerDataResponse responseWithJSONObject: result];
                                  })];
    
    [server addHandlerForMethod: @"POST"
                           path: @"/network/toggle"
                   requestClass: [GCDWebServerDataRequest class]
                   processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerDataRequest * _Nonnull request)
                                  {
                                      NSDictionary *body = [request jsonObject];
                                      [NEHTTPEye setEnabled: [body[@"on"] boolValue]];
                                      return [GCDWebServerDataResponse responseWithJSONObject: (@{ @"code": @1000 })];
                                  })];
}

#if DEBUG
+ (void)testNetwork
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session downloadTaskWithURL: [NSURL URLWithString: @"https://google.com"]];
    [task resume];
    task = [session downloadTaskWithURL: [NSURL URLWithString: @"https://github.com"]];
    [task resume];
    task = [session downloadTaskWithURL: [NSURL URLWithString: @"https://yahoo.com"]];
    [task resume];
}

#endif

@end
