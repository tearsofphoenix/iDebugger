//
//  IDFileScanner.h
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import <Foundation/Foundation.h>

@class GCDWebServer;

@interface IDFileScanner : NSObject

+ (NSArray *)allPath;

+ (void)registerAPI: (GCDWebServer *)server;

@end
