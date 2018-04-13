//
//  HVBase64StaticFile.h
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HVBaseRequestHandler.h"

@interface HVBase64StaticFile : HVBaseRequestHandler {
  NSData *cachedResponse;
}

+ (HVBase64StaticFile *)handler:(NSString*)base64String;

- (instancetype) initWith:(NSString*)base64String NS_DESIGNATED_INITIALIZER;

@end
