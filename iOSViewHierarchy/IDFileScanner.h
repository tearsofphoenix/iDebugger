//
//  IDFileScanner.h
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import <Foundation/Foundation.h>

@interface IDFileScanner : NSObject

+ (NSArray *)hierarchyOfPath: (NSString *)path;

+ (NSDictionary *)allPath;

@end
