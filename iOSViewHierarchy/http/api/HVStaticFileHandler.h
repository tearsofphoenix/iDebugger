//
//  HVStaticFileHandler.h
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HVBaseRequestHandler.h"

@interface HVStaticFileHandler : HVBaseRequestHandler {

  NSString *file;
}

+ (HVStaticFileHandler *)handler:(NSString *)filePath;

- (instancetype)initWithFileName:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

@end
