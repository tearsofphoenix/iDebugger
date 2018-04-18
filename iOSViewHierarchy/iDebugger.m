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
#import "iDebugger.h"
#import "SystemServices.h"

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
        [_server addHandlerForMethod: @"GET"
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
        [_server addHandlerForMethod: @"POST"
                                path: @"/view/update"
                        requestClass: [GCDWebServerDataRequest class]
                   asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                       {
                                           GCDWebServerDataRequest *req = request;
                                           NSDictionary *body = [req jsonObject];
                                           NSLog(@"65 %@", body);
                                           NSInteger viewID = [body[@"target"] integerValue];
                                           dispatch_async(dispatch_get_main_queue(),
                                                          (^
                                                           {
                                                               UIView *view = [IDScanner findViewById: viewID];
                                                               NSLog(@"%@", view);
                                                               NSDictionary *property = body[@"property"];
                                                               [view setValue: body[@"value"]
                                                                       forKey: property[@"name"]];
                                                               
                                                               NSDictionary *responseDic = (@{ @"code": @1000 });                                                               
                                                               GCDWebServerResponse *response = [GCDWebServerDataResponse responseWithJSONObject: responseDic];
                                                               completionBlock(response);
                                                           }));
                                           
                                       })];
        __weak __typeof__(self) weakSelf = self;
        [_server addHandlerForMethod: @"GET"
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
        [_server addHandlerForMethod: @"GET"
                                path: @"/file/list"
                        requestClass: [GCDWebServerRequest class]
                   asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                       {
                                           id result = [IDFileScanner allPath];
                                           NSLog(@"%@", result);
                                           id response = [GCDWebServerDataResponse responseWithJSONObject: result];
                                           completionBlock(response);
                                       })];
        
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

- (void)start
{
    [_server startWithPort: 9449
               bonjourName: nil];
}

#pragma mark -
- (void)handlePreview: (__kindof GCDWebServerRequest * _Nonnull)request
             callback: (GCDWebServerCompletionBlock  _Nonnull)completionBlock
{
    NSString *queryID = [request query][@"id"];
    if (queryID)
    {
        long id = [queryID longLongValue];
        UIView *view = [ IDScanner findViewById: id];
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
