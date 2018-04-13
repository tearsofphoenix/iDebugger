//
//  HVPropertyEditorHandler.m
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import "HVPropertyEditorHandler.h"
#import "HVHierarchyScanner.h"

@implementation HVPropertyEditorHandler : HVBaseRequestHandler

+ (HVPropertyEditorHandler *)handler
{
  return [[HVPropertyEditorHandler alloc] init];
}

- (BOOL)handleRequest:(NSString *)url withHeaders:(NSDictionary *)headers query:(NSDictionary *)query address:(NSString *)address onSocket:(int)socket
{
  if ([super handleRequest:url withHeaders:headers query:query address:address onSocket:socket]) {
    if (query[@"id"] && query[@"type"] && query[@"value"] && query[@"name"]) {
      long id = ((NSString *)query[@"id"]).longLongValue;
      NSString *type = query[@"type"];
      NSString *value = query[@"value"];
      NSString *name = query[@"name"];
      UIView *view = [HVHierarchyScanner findViewById:id];
      if (view) {
        if ([type isEqualToString:@"CGRect"]) {
          CGRect newRect = CGRectFromString(value);
          if (CGRectEqualToRect(newRect, CGRectZero)) {
            return [self writeJSONErrorResponse:@"Bad value format" toSocket:socket];
          } else {
            [view setValue:[NSValue valueWithCGRect:newRect] forKey:name];
            return [self writeJSONResponse:@{@"response": @"OK"} toSocket:socket];
          }
        } else if ([type isEqualToString:@"CGPoint"]) {
          CGPoint newPoint = CGPointFromString(value);
          if (CGPointEqualToPoint(newPoint, CGPointZero)) {
            return [self writeJSONErrorResponse:@"Bad value format" toSocket:socket];
          } else {
            [view setValue:[NSValue valueWithCGPoint:newPoint] forKey:name];
            return [self writeJSONResponse:@{@"response": @"OK"} toSocket:socket];
          }
        }
      }
    }
  }
  return NO;
}

@end
