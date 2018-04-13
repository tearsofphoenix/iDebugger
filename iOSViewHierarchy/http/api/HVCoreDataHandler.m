//
//  HVCoreDataHandler.m
//
//  Copyright (c) 2015 Damian Kolakowski. All rights reserved.
//

#import "HVCoreDataHandler.h"

@implementation HVCoreDataHandler

+ (HVCoreDataHandler *)handler
{
  return [[HVCoreDataHandler alloc] init];
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    contextDictionary = [[NSMutableDictionary alloc] init];
  }
  return self;
}


- (void)pushContext:(NSManagedObjectContext *)context withName:(NSString *)name
{
  contextDictionary[name] = context;
}

- (void)popContext:(NSString*)name
{
  [contextDictionary removeObjectForKey:name];
}

- (NSMutableDictionary*) contextScheme:(NSManagedObjectContext*)context
{
  NSManagedObjectModel* model = (context.persistentStoreCoordinator).managedObjectModel;
  if ( model ) {
    NSMutableDictionary* contextModelDictionary = [[NSMutableDictionary alloc] init];
    NSMutableArray* entityArray = [[NSMutableArray alloc]init];
    for ( NSEntityDescription* descriptor in model.entities) {
      NSMutableDictionary* entityDictionary = [[NSMutableDictionary alloc] init];
      entityDictionary[@"name"] = descriptor.name;
      entityDictionary[@"class"] = descriptor.managedObjectClassName;
      NSMutableArray* propertiesArray = [[NSMutableArray alloc]init];
      for ( NSPropertyDescription* property in descriptor.properties ) {
        NSMutableDictionary* propertyDictionary = [[NSMutableDictionary alloc] init];
        [propertyDictionary setValue:property.name forKey:@"name"];
        if ( [property isKindOfClass:[NSAttributeDescription class]] ) {
          [propertyDictionary setValue:((NSAttributeDescription*)property).attributeValueClassName forKey:@"type"];
        }
        if ( [property isKindOfClass:[NSRelationshipDescription class]] ) {
          [propertyDictionary setValue:((NSRelationshipDescription*)property).destinationEntity.name forKey:@"type"];
        }
        [propertiesArray addObject:propertyDictionary];
      }
      [entityDictionary setValue:propertiesArray forKey:@"properties"];
      [entityArray addObject:entityDictionary];
    }
    contextModelDictionary[@"entities"] = entityArray;
    return contextModelDictionary;
  }
  return nil;
}

- (BOOL) handleSchemeRequest:(int)socket
{
  NSMutableArray* resultArray = [[NSMutableArray alloc] init];
  for ( NSString* contextName in contextDictionary ) {
    NSManagedObjectContext* context = contextDictionary[contextName];
    NSMutableDictionary* contextModelDictionary = [self contextScheme:context];
    contextModelDictionary[@"name"] = contextName;
    [resultArray addObject:contextModelDictionary];
  }
  return [self writeJSONResponse:resultArray toSocket:socket];
}

- (BOOL) handleFetchRequest:(int)socket query:(NSDictionary *)query
{
  NSString* entity = query[@"entity"];
  NSString* predicate = query[@"predicate"];
  NSString* contextName = query[@"context"];
  NSManagedObjectContext* context = contextDictionary[contextName];
  if ( !context ) {
    return [self writeJSONErrorResponse:@"Can't find context" toSocket:socket];
  }
  NSFetchRequest* request = [[NSFetchRequest alloc] init];
  if ( predicate ) {
    @try {
      request.predicate = [NSPredicate predicateWithFormat:predicate];
    }
    @catch (NSException *exception) {
      return [self writeJSONErrorResponse:exception.description toSocket:socket];
    }
  }
  request.entity = [NSEntityDescription entityForName:entity inManagedObjectContext:context];
  if ( !request.entity ) {
    return [self writeJSONErrorResponse:@"Can't find entity" toSocket:socket];
  }
  NSError* error = nil;
  NSArray* result = nil;
  @try {
    result = [context executeFetchRequest:request error:&error];
  }
  @catch (NSException *exception) {
    return [self writeJSONErrorResponse:exception.description toSocket:socket];
  }
  if ( result ) {
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    for ( NSManagedObject* object in result) {
      NSMutableDictionary* dictionary = [[NSMutableDictionary alloc]init];
      for ( NSPropertyDescription* property in request.entity.properties ) {
        if ( [property isKindOfClass:[NSAttributeDescription class]] ) {
          id value = [object valueForKey:property.name];
          if ( [value isKindOfClass:[NSDate class]]) {
            value = @(((NSDate*)value).timeIntervalSince1970);
          }
          if ( [value isKindOfClass:[NSData class]]) {
            value = @"binary";
          }
          [dictionary setValue:value forKey:property.name];
        }
      }
      [resultArray addObject:dictionary];
    }
    return [self writeJSONResponse:resultArray toSocket:socket];
  } else {
    return [self writeJSONErrorResponse:error.description toSocket:socket];
  }
}

- (BOOL)handleRequest:(NSString *)url withHeaders:(NSDictionary *)headers query:(NSDictionary *)query address:(NSString *)address onSocket:(int)socket
{
  if ([super handleRequest:url withHeaders:headers query:query address:address onSocket:socket]) {
      if ( query && query.count > 0 ) {
        return [self handleFetchRequest:socket query:query];
      } else {
        return [self handleSchemeRequest:socket];
      }
  }
  return NO;
}

@end
