//
//  HVStaticFileHandler.m
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import "HVStaticFileHandler.h"
#import "HVBaseRequestHandler.h"

@implementation HVStaticFileHandler : HVBaseRequestHandler

+ (HVStaticFileHandler *)handler:(NSString *)filePath
{
  return [[HVStaticFileHandler alloc] initWithFileName:filePath];
}

- (instancetype)initWithFileName:(NSString *)filePath
{
  self = [super init];
  if (self) {
    file = filePath;
  }
  return self;
}

- (void)dealloc
{
  file = nil;
}

- (BOOL)handleRequest:(NSString *)url withHeaders:(NSDictionary *)headers query:(NSDictionary *)query address:(NSString *)address onSocket:(int)socket
{
  if ([super handleRequest:url withHeaders:headers query:query address:address onSocket:socket]) {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:file ofType:nil];
    if (filePath) {
      NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
      if (data) {
        [self writeData:data toSocket:socket];
      }
    }
    return YES;
  }
  return NO;
}

@end
