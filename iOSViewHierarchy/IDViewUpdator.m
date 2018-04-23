//
//  IDViewUpdator.m
//  iDebugger
//
//  Created by Isaac on 2018/4/23.
//

#import "IDViewUpdator.h"
#import "IDScanner.h"

typedef id (^ IDValueConvertor )(NSString *valueString);

static NSMutableDictionary *kMap = nil;

@implementation IDViewUpdator

+ (void)load
{
    kMap = [NSMutableDictionary dictionary];
    kMap[@"UIColor"] = (^(NSString *valueString)
                        {
                            return IDHexStringToColor(valueString);
                        });
    kMap[@"CGColor"] = (^(NSString *valueString)
                        {
                            return [IDHexStringToColor(valueString) CGColor];
                        });
    kMap[@"CGRect"] = (^(NSString *valueString)
                       {
                           CGRect rect = CGRectFromString(valueString);
                           return [NSValue valueWithCGRect: rect];
                       });
    kMap[@"CGSize"] = (^(NSString *valueString)
                       {
                           CGSize size = CGSizeFromString(valueString);
                           return [NSValue valueWithCGSize: size];
                       });
    kMap[@"CGPoint"] = (^(NSString *valueString)
                        {
                            CGPoint point = CGPointFromString(valueString);
                            return [NSValue valueWithCGPoint: point];
                        });
}

+ (void)updateValue: (NSString *)valueString
           property: (NSDictionary *)property
            forView: (NSInteger)viewID
         completion: (dispatch_block_t)completion
{
    dispatch_async(dispatch_get_main_queue(),
                   (^
                    {
                        UIView *view = [IDScanner findViewById: viewID];
                        NSString *type = property[@"type"];
                        NSString *key = property[@"name"];
                        IDValueConvertor convertor = kMap[type];
                        id value = valueString;
                        if (convertor) {
                            value = convertor(valueString);
                        }
                        [view setValue: value
                                forKey: key];
                        if (completion) {
                            completion();
                        }
                    }));
}
@end
