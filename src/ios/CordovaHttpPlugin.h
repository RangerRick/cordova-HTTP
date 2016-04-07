#import <Foundation/Foundation.h>

#import <Cordova/CDVPlugin.h>

@interface CordovaHttpPlugin : CDVPlugin

- (void)useBasicAuth:(CDVInvokedUrlCommand*)command;
- (void)setHeader:(CDVInvokedUrlCommand*)command;
- (void)enableSSLPinning:(CDVInvokedUrlCommand*)command;
- (void)acceptAllCerts:(CDVInvokedUrlCommand*)command;
- (void)head:(CDVInvokedUrlCommand*)command;
- (void)post:(CDVInvokedUrlCommand*)command;
- (void)get:(CDVInvokedUrlCommand*)command;
- (void)put:(CDVInvokedUrlCommand*)command;
- (void)delete:(CDVInvokedUrlCommand*)command;
- (void)uploadFile:(CDVInvokedUrlCommand*)command;
- (void)downloadFile:(CDVInvokedUrlCommand*)command;

@end
