//
//  iDebugger.m
//  iDebugger
//
//  Created by Isaac on 2018/4/16.
//
#import "GCDWebServer.h"
#import "GCDWebServerFileResponse.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerDataRequest.h"

#import "IDScanner.h"
#import "IDFileAPI.h"
#import "IDViewAPI.h"
#import "IDViewUpdator.h"
#import "iDebugger.h"
#import "SystemServices.h"
#import "IDNetworkAPI.h"
#import "CRToastConfig.h"
#import "CRToastManager.h"

#import <objc/runtime.h>

static iDebugger *kDebugger = nil;
static NSDictionary *kTypeMap = nil;

@interface iDebugger()

@property (nonatomic, strong) GCDWebServer *server;

@end

@implementation iDebugger

+ (void)load
{
    kTypeMap = (@{
                  @"html": @"text/html",
                  @"htm": @"text/html",
                  @"shtml": @"text/html",
                  @"css": @"text/css",
                  @"xml": @"text/xml",
                  @"gif": @"image/gif",
                  @"jpeg": @"image/jpeg",
                  @"jpg": @"image/jpeg",
                  @"js": @"application/javascript",
                  @"atom": @"application/atom+xml",
                  @"rss": @"application/rss+xml",
                  @"mml": @"text/mathml",
                  @"txt": @"text/plain",
                  @"jad": @"text/vnd.sun.j2me.app-descriptor",
                  @"wml": @"text/vnd.wap.wml",
                  @"htc": @"text/x-component",
                  @"png": @"image/png",
                  @"tif": @"image/tiff",
                  @"tiff": @"image/tiff",
                  @"wbmp": @"image/vnd.wap.wbmp",
                  @"ico": @"image/x-icon",
                  @"jng": @"image/x-jng",
                  @"bmp": @"image/x-ms-bmp",
                  @"svg": @"image/svg+xml",
                  @"svgz": @"image/svg+xml",
                  @"webp": @"image/webp",
                  @"woff": @"application/font-woff",
                  @"jar": @"application/java-archive",
                  @"war": @"application/java-archive",
                  @"ear": @"application/java-archive",
                  @"json": @"application/json",
                  @"hqx": @"application/mac-binhex40",
                  @"doc": @"application/msword",
                  @"pdf": @"application/pdf",
                  @"ps": @"application/postscript",
                  @"eps": @"application/postscript",
                  @"ai": @"application/postscript",
                  @"rtf": @"application/rtf",
                  @"m3u8": @"application/vnd.apple.mpegurl",
                  @"xls": @"application/vnd.ms-excel",
                  @"eot": @"application/vnd.ms-fontobject",
                  @"ppt": @"application/vnd.ms-powerpoint",
                  @"wmlc": @"application/vnd.wap.wmlc",
                  @"kml": @"application/vnd.google-earth.kml+xml",
                  @"kmz": @"application/vnd.google-earth.kmz",
                  @"7z": @"application/x-7z-compressed",
                  @"cco": @"application/x-cocoa",
                  @"jardiff": @"application/x-java-archive-diff",
                  @"jnlp": @"application/x-java-jnlp-file",
                  @"run": @"application/x-makeself",
                  @"pl": @"application/x-perl",
                  @"pm": @"application/x-perl",
                  @"prc": @"application/x-pilot",
                  @"pdb": @"application/x-pilot",
                  @"rar": @"application/x-rar-compressed",
                  @"rpm": @"application/x-redhat-package-manager",
                  @"sea": @"application/x-sea",
                  @"swf": @"application/x-shockwave-flash",
                  @"sit": @"application/x-stuffit",
                  @"tcl": @"application/x-tcl",
                  @"tk": @"application/x-tcl",
                  @"der": @"application/x-x509-ca-cert",
                  @"pem": @"application/x-x509-ca-cert",
                  @"crt": @"application/x-x509-ca-cert",
                  @"xpi": @"application/x-xpinstall",
                  @"xhtml": @"application/xhtml+xml",
                  @"xspf": @"application/xspf+xml",
                  @"zip": @"application/zip",
                  @"bin": @"application/octet-stream",
                  @"exe": @"application/octet-stream",
                  @"dll": @"application/octet-stream",
                  @"deb": @"application/octet-stream",
                  @"dmg": @"application/octet-stream",
                  @"iso": @"application/octet-stream",
                  @"img": @"application/octet-stream",
                  @"msi": @"application/octet-stream",
                  @"msp": @"application/octet-stream",
                  @"msm": @"application/octet-stream",
                  @"docx": @"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                  @"xlsx": @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  @"pptx": @"application/vnd.openxmlformats-officedocument.presentationml.presentation",
                  @"mid": @"audio/midi",
                  @"midi": @"audio/midi",
                  @"kar": @"audio/midi",
                  @"mp3": @"audio/mpeg",
                  @"ogg": @"audio/ogg",
                  @"m4a": @"audio/x-m4a",
                  @"ra": @"audio/x-realaudio",
                  @"3gpp": @"video/3gpp",
                  @"3gp": @"video/3gpp",
                  @"ts": @"video/mp2t",
                  @"mp4": @"video/mp4",
                  @"mpeg": @"video/mpeg",
                  @"mpg": @"video/mpeg",
                  @"mov": @"video/quicktime",
                  @"webm": @"video/webm",
                  @"flv": @"video/x-flv",
                  @"m4v": @"video/x-m4v",
                  @"mng": @"video/x-mng",
                  @"asx": @"video/x-ms-asf",
                  @"asf": @"video/x-ms-asf",
                  @"wmv": @"video/x-ms-wmv",
                  @"avi": @"video/x-msvideo"
                  });
}

+ (NSString *)typeForPath: (NSString *)path
{
    NSString *ext = [path pathExtension];
    NSString *type = kTypeMap[ext];
    return type ? type : @"application/octet-stream";
}

+ (instancetype)instance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kDebugger = [[self alloc] init];
    });
    return kDebugger;
}

- (id)init
{
    if ((self = [super init]))
    {
        _server = [[GCDWebServer alloc] init];
        [_server addHandlerForMethod: @"POST"
                                path: @"/connect"
                        requestClass: [GCDWebServerRequest class]
                        processBlock: (^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request)
                                       {
                                           id response = [GCDWebServerDataResponse responseWithJSONObject: (@{@"code": @1000})];
                                           return response;
                                       })];
        
        [IDViewAPI registerAPI: _server];
        [IDFileAPI registerAPI: _server];
        [IDNetworkAPI registerAPI: _server];
        
        [_server addHandlerForMethod: @"GET"
                                path: @"/system/info"
                        requestClass: [GCDWebServerRequest class]
                   asyncProcessBlock: (^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock)
                                       {
                                           id result = [[SystemServices sharedServices] allSystemInformation];
                                           NSLog(@"%@", result);
                                           id response = [GCDWebServerDataResponse responseWithJSONObject: result];
                                           completionBlock(response);
                                       })];
    }
    return self;
}

static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    return attributes;
}

- (void)start
{
//    Class viewClass = [UIView class];
//    uint outCount = 0;
//    objc_property_t *properties = class_copyPropertyList(viewClass, &outCount);
//    for (int i = 0; i < outCount; ++i) {
//        objc_property_t property = properties[i];
//        const char *propName = property_getName(property);
//        if(propName) {
//            const char *propType = getPropertyType(property);
//            NSString *propertyName = [NSString stringWithCString:propName
//                                                        encoding:[NSString defaultCStringEncoding]];
//            NSString *propertyType = [NSString stringWithCString:propType
//                                                        encoding:[NSString defaultCStringEncoding]];
//            NSLog(@"%@ %@", propertyName, propertyType);
//        }
//    }
    uint16_t port = 9449;
    [_server startWithPort: port
               bonjourName: nil];
    NSString *ip = [[SystemServices sharedServices] wiFiIPAddress];
    NSString *text = [NSString stringWithFormat: @"debugger run at http://%@:%d", ip, port];
    NSDictionary *options = @{
                              kCRToastTextKey : text,
                              kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                              kCRToastBackgroundColorKey : [UIColor redColor],
                              kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                              kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeGravity),
                              kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionLeft),
                              kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionRight)
                              };
    [CRToastManager showNotificationWithOptions: options
                                completionBlock: nil];
}

@end
