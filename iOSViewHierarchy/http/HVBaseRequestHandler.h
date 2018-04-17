//
//  HVBaseRequestHandler.h
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HVRequestHandler <NSObject>
@required

- (BOOL)handleRequest:(NSString *)url withHeaders:(NSDictionary *)headers query:(NSDictionary *)query address:(NSString *)address onSocket:(int)socket;

@end

@interface HVBaseRequestHandler : NSObject <HVRequestHandler>

- (BOOL)writeData:(NSData*)data toSocket:(int)socket;

- (BOOL)writeJSONResponse:(id)object toSocket:(int)socket;

- (BOOL)writeJSONErrorResponse:(NSString*)error toSocket:(int)socket;

@end
