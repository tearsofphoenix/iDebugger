//
//  iDebugger.m
//  iDebugger
//
//  Created by Isaac on 2018/4/16.
//
#import "GCDWebServer.h"
#import "GCDWebServerFileResponse.h"
#import "GCDWebServerDataResponse.h"

#import "HVHierarchyScanner.h"

#import "iDebugger.h"

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
                                path: @"/snapshot"
                        requestClass: [GCDWebServerRequest class]
                   asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                       {
                                           NSArray *hierarchyDict = [HVHierarchyScanner hierarchySnapshot];
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
        __weak __typeof__(self) weakSelf = self;
        [_server addHandlerForMethod: @"GET"
                                path: @"/preview"
                        requestClass: [GCDWebServerRequest class]
                   asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                       {
                                           dispatch_async(dispatch_get_main_queue(), (^
                                                                                      {
                                                                                          [weakSelf handlePreview: request
                                                                                                         callback: completionBlock];
                                                                                      }));
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
        UIView *view = [HVHierarchyScanner findViewById: id];
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
