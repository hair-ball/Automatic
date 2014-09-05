//
//  HttpManager.h
//  Automatic
//
//  Created by sagles on 14-9-3.
//  Copyright (c) 2014年 IKIS. All rights reserved.
//

/**
 *  请求结果类型
 */
typedef NS_ENUM(NSUInteger, RequestResultType)
{
    /*!
     @brief 请求成功
     */
    RequestResultTypeRequestFinished,
    /*!
     @brief 请求失败
     */
    RequestResultTypeRequestFailed,
    /*!
     @brief 返回数据解析成功
     */
    RequestResultTypeParseFinished,
    /*!
     @brief 返回数据解析失败
     */
    RequestResultTypeParserFailed,
    /*!
     @brief 接口返回数据标识为失败
     */
    RequestResultTypeReturnError,
    /*!
     @brief 接口返回数据标识为成功
     */
    RequestResultTypeReturnSuccess
};

/**
 *  请求类型
 */
typedef NS_ENUM(NSInteger, MethodType)
{
    /*!
     @brief GET
     */
    MethodTypeGET,
    /*!
     @brief POST
     */
    MethodTypePOST
};

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface HttpManager : NSObject

/**
 *  服务器地址，必须在请求之前设置
 */
@property (nonatomic, strong) NSURL *baseUrl;


+ (instancetype)defaultManager;

/**
 *  请求
 *
 *  @param methodType 请求类型，这里只支持GET和POST
 *  @param api        接口（与服务器地址拼接后进行请求）
 *  @param parameters 参数
 *  @param complete   完成的回调
 */
- (void)requestWithMethodType:(MethodType)methodType
                          api:(NSString *)api
                   parameters:(NSDictionary *)parameters
                     complete:(void (^)(RequestResultType type, int code))complete;

/**
 *  返回是否有网络
 *
 *  @return BOOL
 */
- (BOOL)isNetworkReachable;

@end
