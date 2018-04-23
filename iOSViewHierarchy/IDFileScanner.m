//
//  IDFileScanner.m
//  iDebugger
//
//  Created by Isaac on 2018/4/17.
//

#import "IDFileScanner.h"

static NSMutableDictionary *infoOfFile(NSString *path)
{
    NSURL *bundleURL = [NSURL fileURLWithPath: path];
    NSArray *keys = @[NSURLNameKey, NSURLPathKey, NSURLIsDirectoryKey, NSURLCreationDateKey, NSURLFileSizeKey];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary: [bundleURL resourceValuesForKeys: keys
                                                                                                            error: NULL]];
    result[NSURLCreationDateKey] = @([result[NSURLCreationDateKey] timeIntervalSince1970]);
    return result;
}

static NSArray *contentOfFolder(NSString *path)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *bundleURL = [NSURL fileURLWithPath: path];
    NSArray *keys = @[NSURLNameKey, NSURLPathKey, NSURLIsDirectoryKey, NSURLCreationDateKey, NSURLFileSizeKey];
    NSArray *contents = [fileManager contentsOfDirectoryAtURL: bundleURL
                                   includingPropertiesForKeys: keys
                                                      options: NSDirectoryEnumerationSkipsHiddenFiles
                                                        error: NULL];
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *fileURL in contents)
    {
        NSDictionary *dict = [fileURL resourceValuesForKeys: keys
                                                      error: NULL];
        NSMutableDictionary *obj = [NSMutableDictionary dictionaryWithDictionary: dict];
        if ([dict[NSURLIsDirectoryKey] boolValue])
        {
            NSArray *subcontents = contentOfFolder(dict[NSURLPathKey]);
            obj[@"contents"] = subcontents;
        }
        obj[NSURLCreationDateKey] = @([dict[NSURLCreationDateKey] timeIntervalSince1970]);
        [result addObject: obj];
    }
    return result;
}

@implementation IDFileScanner

+ (NSArray *)allPath
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSMutableArray *result = [NSMutableArray array];
    NSArray *documents = contentOfFolder(path);
    NSMutableDictionary *info = infoOfFile(path);
    info[@"contents"] = documents;
    [result addObject: info];
    path = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSArray *libraries = contentOfFolder(path);
    info = infoOfFile(path);
    info[@"contents"] = libraries;
    [result addObject: info];
    
    return result;
}

@end
