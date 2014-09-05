//
//  HttpManager.m
//  Automatic
//
//  Created by sagles on 14-9-3.
//  Copyright (c) 2014年 IKIS. All rights reserved.
//


#import "HttpManager.h"

@interface HttpManager ()

/**
 *  <#Description#>
 */
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

@end

@implementation HttpManager

+ (instancetype)defaultManager
{
    static HttpManager *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (void)setBaseUrl:(NSURL *)baseUrl
{
    if (_baseUrl != baseUrl) {
        _baseUrl = baseUrl;
        self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseUrl];
        self.manager.operationQueue.maxConcurrentOperationCount = NSIntegerMax;
        self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
//        [self.manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        
//        self.manager.requestSerializer.timeoutInterval = 10.f;
        
        NSOperationQueue *queue = self.manager.operationQueue;
        [self.manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusReachableViaWWAN:
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    [queue setSuspended:NO];
                    break;
                case AFNetworkReachabilityStatusUnknown:
                case AFNetworkReachabilityStatusNotReachable:
                default:
                    [queue setSuspended:YES];
                    break;
            }
        }];
    }
}

- (BOOL)isNetworkReachable
{
    return self.manager.reachabilityManager.reachable;
}

#pragma mark - Private methods

- (void)requestWithMethodType:(MethodType)methodType
                          api:(NSString *)api
                   parameters:(NSDictionary *)parameters
                     complete:(void (^)(RequestResultType, int))complete
{
    __weak typeof(self) wSelf = self;
    switch (methodType) {
        case MethodTypeGET:
        {
            [self.manager GET:api
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          
                          [wSelf completeWithResponseObject:responseObject Block:complete];
                          
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (complete) {
                              complete(RequestResultTypeRequestFailed,0);
                          }
                      }];
        }
            break;
        case MethodTypePOST:
        {
            //这里使用了multipart http request，使用的form-data。不带constructingBodyWithBlock的是用的raw
            [self.manager POST:api
                    parameters:parameters
     constructingBodyWithBlock:nil
                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                           
                           [wSelf completeWithResponseObject:responseObject Block:complete];
                           
                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                           if (complete) {
                               complete(RequestResultTypeRequestFailed,0);
                           }
                       }];
        }
            break;
        default:
            break;
    }
}

- (void)completeWithResponseObject:(id)responseObject Block:(void (^)(RequestResultType, int))complete
{
    NSLog(@"%@",responseObject);
    
    if (complete) {
        
        complete(RequestResultTypeRequestFinished,0);
        
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            complete(RequestResultTypeParserFailed,0);
        }
        else {
#warning 判断成功需要根据实际接口返回
            int code = [[responseObject objectForKey:@"code"] intValue];
            if (code == 1000) {
                complete(RequestResultTypeReturnSuccess,0);
            }
            else {
                complete(RequestResultTypeReturnError,code);
            }
        }
    }
}

@end
