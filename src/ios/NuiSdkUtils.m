//
//  Utils.m
//  NUIdemo
//
//  Created by zhouguangdong on 2019/12/26.
//  Copyright © 2019 Alibaba idst. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuiSdkUtils.h"
#include <netdb.h>
#include <arpa/inet.h>
#import <AdSupport/ASIdentifierManager.h>
#import "AccessToken.h"

@implementation NuiSdkUtils
//Get Document Dir
-(NSString *)dirDoc {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    TLog(@"app_home_doc: %@",documentsDirectory);
    return documentsDirectory;
}

//create dir for saving files
-(NSString *)createDir {
    NSString *documentsPath = [self dirDoc];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *testDirectory = [documentsPath stringByAppendingPathComponent:@"voices"];
    // 创建目录
    BOOL res=[fileManager createDirectoryAtPath:testDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    if (res) {
        TLog(@"文件夹创建成功");
    }else
        TLog(@"文件夹创建失败");
    return testDirectory;
}

-(void) getTicket:(NSMutableDictionary*) dictM {
    //用户申请阿里云账号和appkey后填入才可使用。
    NSString *ak_id = @"";
    NSString *ak_secret = @"";
    NSString *app_key = @"";
    NSString *token = @"";
    token = [self generateToken:ak_id withSecret:ak_secret];
    if (token == NULL) {
        NSLog(@"generate token failed");
        return;
    }
    [dictM setObject:app_key forKey:@"app_key"];
    [dictM setObject:token forKey:@"token"];
}

-(void) getAuthTicket:(NSMutableDictionary*) dictM {
    //用户申请阿里云账号和appkey后填入才可使用。
    NSString *ak_id = @"";
    NSString *ak_secret = @"";
    NSString *app_key = @"";
    NSString *sdk_code = @"";
    [dictM setObject:@"wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1" forKey:@"url"];
    [dictM setObject:app_key forKey:@"app_key"];
    [dictM setObject:ak_id forKey:@"ak_id"];
    [dictM setObject:ak_secret forKey:@"ak_secret"];
    [dictM setObject:sdk_code forKey:@"sdk_code"];
}

-(NSString*)generateToken:(NSString*)accessKey withSecret:(NSString*)accessSecret{
    AccessToken *accessToken = [[AccessToken alloc]initWithAccessKeyId:accessKey andAccessSecret:accessSecret];
    [accessToken apply];
    NSLog(@"Token expire time is %ld",[accessToken expireTime]);
    return [accessToken token];
}

-(NSString*) getDirectIp {
    const int MAX_HOST_IP_LENGTH = 16;
    struct hostent *remoteHostEnt = gethostbyname("nls-gateway-inner.aliyuncs.com");
    if(remoteHostEnt == NULL) {
        NSLog(@"demo get host failed!");
    }
    struct in_addr *remoteInAddr = (struct in_addr *) remoteHostEnt->h_addr_list[0];
    //ip = inet_ntoa(*remoteInAddr);
    char ip_[MAX_HOST_IP_LENGTH];
    inet_ntop(AF_INET, (void *)remoteInAddr, ip_, MAX_HOST_IP_LENGTH);
    NSString *ip=[NSString stringWithUTF8String:ip_];
    return ip;
}

@end
