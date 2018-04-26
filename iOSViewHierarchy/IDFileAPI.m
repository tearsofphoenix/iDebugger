//
//  IDFileScanner.m
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import "IDFileAPI.h"
#import "GCDWebServer.h"
#import "GCDWebServerFileResponse.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"
#import "iDebugger.h"

static NSMutableDictionary *infoOfFile(NSString *path)
{
    NSURL *bundleURL = [NSURL fileURLWithPath: path];
    NSArray *keys = @[NSURLNameKey, NSURLPathKey, NSURLIsDirectoryKey, NSURLCreationDateKey, NSURLFileSizeKey];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary: [bundleURL resourceValuesForKeys: keys
                                                                                                            error: NULL]];
    result[NSURLCreationDateKey] = @([result[NSURLCreationDateKey] timeIntervalSince1970]);
    return result;
}

static NSArray *contentOfFolder(NSString *path)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *bundleURL = [NSURL fileURLWithPath: path];
    NSArray *keys = @[NSURLNameKey, NSURLPathKey, NSURLIsDirectoryKey, NSURLCreationDateKey, NSURLFileSizeKey];
    NSArray *contents = [fileManager contentsOfDirectoryAtURL: bundleURL
                                   includingPropertiesForKeys: keys
                                                      options: NSDirectoryEnumerationSkipsHiddenFiles
                                                        error: NULL];
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *fileURL in contents)
    {
        NSDictionary *dict = [fileURL resourceValuesForKeys: keys
                                                      error: NULL];
        NSMutableDictionary *obj = [NSMutableDictionary dictionaryWithDictionary: dict];
        if ([dict[NSURLIsDirectoryKey] boolValue])
        {
            NSArray *subcontents = contentOfFolder(dict[NSURLPathKey]);
            obj[@"contents"] = subcontents;
        }
        obj[NSURLCreationDateKey] = @([dict[NSURLCreationDateKey] timeIntervalSince1970]);
        [result addObject: obj];
    }
    return result;
}

@implementation IDFileAPI

+ (NSArray *)allPath
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSMutableArray *result = [NSMutableArray array];
    NSArray *documents = contentOfFolder(path);
    NSMutableDictionary *info = infoOfFile(path);
    info[@"contents"] = documents;
    [result addObject: info];
    path = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSArray *libraries = contentOfFolder(path);
    info = infoOfFile(path);
    info[@"contents"] = libraries;
    [result addObject: info];
    
    return result;
}

+ (void)registerAPI: (GCDWebServer *)server
{
    [server addHandlerForMethod: @"GET"
                           path: @"/file/list"
                   requestClass: [GCDWebServerRequest class]
              asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                  {
                                      id result = [IDFileAPI allPath];
                                      NSLog(@"%@", result);
                                      id response = [GCDWebServerDataResponse responseWithJSONObject: result];
                                      completionBlock(response);
                                  })];
    
    [server addHandlerForMethod: @"GET"
                           path: @"/file/one"
                   requestClass: [GCDWebServerRequest class]
              asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                  {
                                      NSString *path = [request query][@"path"];
                                      NSData *data = [NSData dataWithContentsOfFile: path
                                                                            options: 0
                                                                              error: NULL];
                                      id response = [GCDWebServerDataResponse responseWithData: data
                                                                                   contentType: @"text/html"];
                                      completionBlock(response);
                                  })];
    
    [server addHandlerForMethod: @"POST"
                           path: @"/file/remove"
                   requestClass: [GCDWebServerDataRequest class]
                   processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerDataRequest * _Nonnull request)
                                  {
                                      NSFileManager *manager = [NSFileManager defaultManager];
                                      NSDictionary *body = [request jsonObject];
                                      NSString *path = body[NSURLPathKey];
                                      NSLog(@"105 %@", path);
                                      NSError *error = nil;
                                      if([manager removeItemAtPath: path
                                                             error: &error])
                                      {
                                          return [GCDWebServerDataResponse responseWithJSONObject: (@{
                                                                                                      @"code": @1000
                                                                                                      })];
                                      } else {
                                          return [GCDWebServerDataResponse responseWithJSONObject: (@{
                                                                                                      @"code": @2000,
                                                                                                      @"message": [error description]
                                                                                                      })];
                                      }
                                  })];

    [server addHandlerForMethod: @"POST"
                           path: @"/file/download"
                   requestClass: [GCDWebServerDataRequest class]
                   processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerDataRequest * _Nonnull request)
                                  {
                                      NSDictionary *body = [request jsonObject];
                                      NSString *path = body[NSURLPathKey];
                                      NSData *data = [NSData dataWithContentsOfFile: path];
                                      return [GCDWebServerDataResponse responseWithData: data
                                                                            contentType: [iDebugger typeForPath: path]];
                                  })];

    [server addHandlerForMethod: @"POST"
                           path: @"/file/rename"
                   requestClass: [GCDWebServerDataRequest class]
                   processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerDataRequest * _Nonnull request)
                                  {
                                      NSFileManager *manager = [NSFileManager defaultManager];
                                      NSDictionary *body = [request jsonObject];
                                      NSString *path = body[@"file"][NSURLPathKey];
                                      NSString *name = body[@"name"];
                                      NSString *newPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent: name];
                                      NSLog(@"129 %@ %@ %@", path, name, newPath);
                                      NSError *error = nil;
                                      if([manager moveItemAtPath: path
                                                          toPath: newPath
                                                           error: &error])
                                      {
                                          return [GCDWebServerDataResponse responseWithJSONObject: (@{
                                                                                                      @"code": @1000
                                                                                                      })];
                                      } else {
                                          return [GCDWebServerDataResponse responseWithJSONObject: (@{
                                                                                                      @"code": @2000,
                                                                                                      @"message": [error description]
                                                                                                      })];
                                      }
                                  })];
}

@end
