//
//  IDViewUpdator.h
//  iDebugger
//
//  Created by Isaac on 2018/4/23.
//

#import <Foundation/Foundation.h>

@interface IDViewUpdator : NSObject

+ (void)updateValue: (NSString *)valueString
           property: (NSDictionary *)property
            forView: (NSInteger)viewID
         completion: (dispatch_block_t)completion;

@end
