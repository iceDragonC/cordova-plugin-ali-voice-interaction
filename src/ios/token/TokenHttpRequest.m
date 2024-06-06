//
//  TokenHttpRequest.m
//  NlsSdk
//
//  Created by Songsong Shao on 2018/10/29.
//  Copyright © 2018 Songsong Shao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>
#import "TokenHttpRequest.h"

static NSString *HEADER_CONTENT_TYPE = @"Content-Type";
static NSString *HEADER_ACCEPT = @"Accept";
static NSString *HEADER_ACCEPT_ENCODING = @"Accept-Encoding";
static NSString *HEADER_DATE = @"Date";
static NSString *HEADER_AUTHORIZATION = @"Authorization";
static NSString *HEADER_CONTENT_MD5 = @"Content-MD5";
//body为空字符串，故bodymd5无需计算即可
static NSString *bodyMd5 = @"1B2M2Y8AsgTpgAmY7PhCfg==";
static NSString *url = @"https://nls-meta.cn-shanghai.aliyuncs.com/pop/2018-05-18/tokens";

static NSString *method = @"POST";
static NSString *contentType = @"application/octet-stream;charset=utf-8";
static NSString *accept = @"application/json";
static NSString *acceptEncoding = @"identity";

@interface TokenHttpRequest(){
    
    
}
@property(nonatomic)NSMutableDictionary *headers;
@property(nonatomic)NSMutableURLRequest *httpRequest;
@end

@implementation TokenHttpRequest

NSString *dateTime = nil;

-(id)init {
    self = [super init];
    
    NSURL *nsurl = [NSURL URLWithString:url];
    _httpRequest = [NSMutableURLRequest requestWithURL:nsurl];
    [_httpRequest setTimeoutInterval:3.0];
    [_httpRequest setHTTPMethod:@"POST"];
    
    _headers = [[NSMutableDictionary alloc]init];
    [_headers setValue:contentType forKey:HEADER_CONTENT_TYPE];
    [_headers setValue:accept forKey:HEADER_ACCEPT];
    [_headers setValue:acceptEncoding forKey:HEADER_ACCEPT_ENCODING];
    [_headers setValue:bodyMd5 forKey:HEADER_CONTENT_MD5];
    
    return self;
}

-(NSString*)authorize:(NSString *)accessKeyId with:(NSString *)accessSecret{
    dateTime = [self getGMTDate];
    NSLog(@"Authorize date time is: %@",dateTime);
    [_headers setValue:dateTime forKey:HEADER_DATE];
    
    NSString *toSign = [[NSString alloc] initWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@",method,accept,bodyMd5,contentType,dateTime,@"/pop/2018-05-18/tokens"];
    
    NSLog(@"String to sign is : %@",toSign);
    
    
    NSString *signature = [self getSign:toSign accessKeySecret:accessSecret];
    NSString *authHeader = [[NSString alloc] initWithFormat:@"acs %@:%@",accessKeyId,signature];
    [_headers setValue:authHeader forKey:HEADER_AUTHORIZATION];
    
    return [self httpPost];
}

-(NSString* )httpPost{
    NSArray *allKeys = _headers.allKeys ;
    for (int i = 0; i< [_headers count]; i++) {
        NSString *key = allKeys[i];
        NSString *value = [_headers valueForKey:key];
        //设置http请求头
        [_httpRequest setValue:value forHTTPHeaderField:key];
    }
//    [_httpRequest setHTTPBody:nil];
    NSData *returnData = [NSURLConnection sendSynchronousRequest:_httpRequest returningResponse:nil error:nil];
    NSString *data =[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    return data;
}

-(NSString *)getGMTDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss 'GMT'"];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    return dateString;
}

-(NSString *)getSign:(NSString *)stringtoSign accessKeySecret:(NSString *)secret{
    const char *cKey  = [secret cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [stringtoSign cStringUsingEncoding:NSUTF8StringEncoding];
    uint8_t cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA1_DIGEST_LENGTH];
    NSString *strHash = [HMAC base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return strHash;
}
@end
