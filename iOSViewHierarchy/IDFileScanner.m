//
//  IDFileScanner.m
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import "IDFileScanner.h"

@implementation IDFileScanner

+ (NSArray *)hierarchyOfPath: (NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *bundleURL = [NSURL fileURLWithPath: path];
    NSArray *keys = @[NSURLNameKey, NSURLIsDirectoryKey, NSURLCreationDateKey, NSURLFileSizeKey];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL: bundleURL
                                          includingPropertiesForKeys: keys
                                                             options: NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler: (^BOOL(NSURL *url, NSError *error)
                                                                       {
                                                                           NSLog(@"[Error] %@ (%@)", error, url);
                                                                           return YES;
                                                                       })];
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *fileURL in enumerator)
    {
        NSDictionary *dict = [fileURL resourceValuesForKeys: keys
                                                      error: NULL];
        NSMutableDictionary *obj = [NSMutableDictionary dictionaryWithDictionary: dict];
        obj[NSURLCreationDateKey] = @([dict[NSURLCreationDateKey] timeIntervalSince1970]);
        [result addObject: obj];
    }
    return result;
}

+ (NSDictionary *)allPath
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"Documents"] = [self hierarchyOfPath: path];
    path = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    result[@"Library"] = [self hierarchyOfPath: path];
    path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    result[@"Caches"] = [self hierarchyOfPath: path];
    return result;
}

@end
