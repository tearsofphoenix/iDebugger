//
//  IDNetworkAPI.h
//  iDebugger
//
//  Created by Isaac on 2018/4/26.
//

#import <Foundation/Foundation.h>

@class GCDWebServer;

@interface IDNetworkAPI : NSObject

+ (void)registerAPI: (GCDWebServer *)server;

@end
