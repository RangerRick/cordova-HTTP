#import "CordovaHttpPlugin.h"
#import "CDVFile.h"
#import "TextResponseSerializer.h"
#import "HttpManager.h"
#import "AFHTTPSessionManager.h"

@interface CordovaHttpPlugin()

- (void)setRequestHeaders:(NSDictionary*)headers;

@end


@implementation CordovaHttpPlugin {
    AFHTTPRequestSerializer *requestSerializer;
}

- (void)pluginInitialize {
    requestSerializer = [AFHTTPRequestSerializer serializer];
}

- (void)setRequestHeaders:(NSDictionary*)headers {
  AFHTTPRequestOperationManager *manager = [HttpManager sharedClient];
  manager.requestSerializer = [AFHTTPRequestSerializer serializer];
  [self setRequestHeaders:headers forManager:manager];
}

- (void)setRequestHeaders:(NSDictionary*)headers forManager:(AFHTTPRequestOperationManager*)manager {
    [requestSerializer.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
}

- (void)useBasicAuth:(CDVInvokedUrlCommand*)command {
    NSString *username = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];

    [requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setHeader:(CDVInvokedUrlCommand*)command {
    NSString *header = [command.arguments objectAtIndex:0];
    NSString *value = [command.arguments objectAtIndex:1];

    [requestSerializer setValue:value forHTTPHeaderField:header];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setTimeouts:(CDVInvokedUrlCommand*)command {
    //long connectionTimeout = [[command.arguments objectAtIndex:0] longValue];
    long readTimeout = [[command.arguments objectAtIndex:1] longValue];

    requestSerializer.timeoutInterval = (readTimeout / 1000.0);
}

- (void)enableSSLPinning:(CDVInvokedUrlCommand*)command {
    bool enable = [[command.arguments objectAtIndex:0] boolValue];
    if (enable) {
        [HttpManager sharedClient].securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    } else {
        [HttpManager sharedClient].securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)acceptAllCerts:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    bool allow = [[command.arguments objectAtIndex:0] boolValue];

    [HttpManager sharedClient].securityPolicy.allowInvalidCertificates = allow;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)checkRequestTimeout:(NSTimer*)timer {
  AFHTTPRequestOperation* op = [timer userInfo];
  if (![op isFinished]) {
    NSLog(@"Request has timed out: %@ %@", [[op request] HTTPMethod],[[op request] URL]);
    [op cancel];
  }
}

- (void)head:(CDVInvokedUrlCommand*)command {
   HttpManager *manager = [HttpManager sharedClient];
   NSString *url = [command.arguments objectAtIndex:0];
   NSDictionary *parameters = [command.arguments objectAtIndex:1];
   NSDictionary *headers = [command.arguments objectAtIndex:2];
   [self setRequestHeaders: headers];

   CordovaHttpPlugin* __weak weakSelf = self;

   manager.responseSerializer = [TextResponseSerializer serializer];
   AFHTTPRequestOperation* op = [manager HEAD:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:responseObject forKey:@"data"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:[error localizedDescription] forKey:@"error"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   }];
  [NSTimer scheduledTimerWithTimeInterval:requestSerializer.timeoutInterval target:weakSelf selector:@selector(checkRequestTimeout:) userInfo:op repeats:false];
}

- (void)post:(CDVInvokedUrlCommand*)command {
   NSString *url = [command.arguments objectAtIndex:0];
   NSDictionary *parameters = [command.arguments objectAtIndex:1];
   NSDictionary *headers = [command.arguments objectAtIndex:2];

   AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

   manager.requestSerializer = [AFJSONRequestSerializer serializer];
   manager.responseSerializer = [AFJSONResponseSerializer serializer];

   [self setRequestHeaders: headers forManager:manager];

   //NSLog(@"posting parameters: %@", parameters);
   CordovaHttpPlugin* __weak weakSelf = self;
   AFHTTPRequestOperation* op = [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
     [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:responseObject forKey:@"data"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:[error localizedDescription] forKey:@"error"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   }];
  [NSTimer scheduledTimerWithTimeInterval:requestSerializer.timeoutInterval target:weakSelf selector:@selector(checkRequestTimeout:) userInfo:op repeats:false];
}

- (void)get:(CDVInvokedUrlCommand*)command {
   HttpManager *manager = [HttpManager sharedClient];
   NSString *url = [command.arguments objectAtIndex:0];
   NSDictionary *parameters = [command.arguments objectAtIndex:1];
   NSDictionary *headers = [command.arguments objectAtIndex:2];
   [self setRequestHeaders: headers];

   CordovaHttpPlugin* __weak weakSelf = self;

   manager.responseSerializer = [TextResponseSerializer serializer];
   AFHTTPRequestOperation* op = [manager GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:responseObject forKey:@"data"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:[error localizedDescription] forKey:@"error"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   }];
  [NSTimer scheduledTimerWithTimeInterval:requestSerializer.timeoutInterval target:weakSelf selector:@selector(checkRequestTimeout:) userInfo:op repeats:false];
}

- (void)put:(CDVInvokedUrlCommand*)command {
   HttpManager *manager = [HttpManager sharedClient];
   NSString *url = [command.arguments objectAtIndex:0];
   NSDictionary *parameters = [command.arguments objectAtIndex:1];
   NSDictionary *headers = [command.arguments objectAtIndex:2];
   [self setRequestHeaders: headers];

   CordovaHttpPlugin* __weak weakSelf = self;

   manager.responseSerializer = [TextResponseSerializer serializer];
   AFHTTPRequestOperation* op = [manager PUT:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:responseObject forKey:@"data"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
      [dictionary setObject:[error localizedDescription] forKey:@"error"];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
      [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   }];
  [NSTimer scheduledTimerWithTimeInterval:requestSerializer.timeoutInterval target:weakSelf selector:@selector(checkRequestTimeout:) userInfo:op repeats:false];
}

- (void)uploadFile:(CDVInvokedUrlCommand*)command {
    HttpManager *manager = [HttpManager sharedClient];
    NSString *url = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    NSString *filePath = [command.arguments objectAtIndex: 3];
    NSString *name = [command.arguments objectAtIndex: 4];

    NSURL *fileURL = [NSURL fileURLWithPath: filePath];

    [self setRequestHeaders: headers];

    CordovaHttpPlugin* __weak weakSelf = self;
    manager.responseSerializer = [TextResponseSerializer serializer];
    AFHTTPRequestOperation* op = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSError *error;
        [formData appendPartWithFileURL:fileURL name:name error:&error];
        if (error) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:[NSNumber numberWithInt:500] forKey:@"status"];
            [dictionary setObject:@"Could not add image to post body." forKey:@"error"];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
        [dictionary setObject:[error localizedDescription] forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
  [NSTimer scheduledTimerWithTimeInterval:requestSerializer.timeoutInterval target:weakSelf selector:@selector(checkRequestTimeout:) userInfo:op repeats:false];
}


- (void)downloadFile:(CDVInvokedUrlCommand*)command {
    HttpManager *manager = [HttpManager sharedClient];
    NSString *url = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    NSString *filePath = [command.arguments objectAtIndex: 3];

    [self setRequestHeaders: headers];

    CordovaHttpPlugin* __weak weakSelf = self;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFHTTPRequestOperation* op = [manager GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        /*
         *
         * Licensed to the Apache Software Foundation (ASF) under one
         * or more contributor license agreements.  See the NOTICE file
         * distributed with this work for additional information
         * regarding copyright ownership.  The ASF licenses this file
         * to you under the Apache License, Version 2.0 (the
         * "License"); you may not use this file except in compliance
         * with the License.  You may obtain a copy of the License at
         *
         *   http://www.apache.org/licenses/LICENSE-2.0
         *
         * Unless required by applicable law or agreed to in writing,
         * software distributed under the License is distributed on an
         * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
         * KIND, either express or implied.  See the License for the
         * specific language governing permissions and limitations
         * under the License.
         *
         * Modified by Andrew Stephan for Sync OnSet
         *
        */
        // Download response is okay; begin streaming output to file
        NSString* parentPath = [filePath stringByDeletingLastPathComponent];

        // create parent directories if needed
        NSError *error;
        if ([[NSFileManager defaultManager] createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:[NSNumber numberWithInt:500] forKey:@"status"];
            if (error) {
                [dictionary setObject:[NSString stringWithFormat:@"Could not create path to save downloaded file: %@", [error localizedDescription]] forKey:@"error"];
            } else {
                [dictionary setObject:@"Could not create path to save downloaded file" forKey:@"error"];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        NSData *data = (NSData *)responseObject;
        if (![data writeToFile:filePath atomically:YES]) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:[NSNumber numberWithInt:500] forKey:@"status"];
            [dictionary setObject:@"Could not write the data to the given filePath." forKey:@"error"];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        CDVFile *file = [[CDVFile alloc] init];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
        [dictionary setObject:[file getDirectoryEntry:filePath isDirectory:NO] forKey:@"file"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:[NSNumber numberWithLong:operation.response.statusCode] forKey:@"status"];
        [dictionary setObject:[error localizedDescription] forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
  [NSTimer scheduledTimerWithTimeInterval:requestSerializer.timeoutInterval target:weakSelf selector:@selector(checkRequestTimeout:) userInfo:op repeats:false];
}

@end
