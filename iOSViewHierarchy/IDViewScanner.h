//
//  IDViewScanner.h
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import <Foundation/Foundation.h>
@protocol IDScanner<NSObject>

+ (NSArray *)scanPropertyOfObject: (id)object;

@end

@interface IDViewScanner : NSObject<IDScanner>

+ (void)addPropertyArray: (NSArray *)array
                 forName: (NSString *)name;

+ (void)removePropertyForName: (NSString *)name;

+ (NSArray *)scanProperties: (NSArray *)properties
                     object: (id) obj;
@end
