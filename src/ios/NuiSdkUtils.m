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
#import "token/AccessToken.h"

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
    //郑重提示:
    //  您的账号信息ak_id和ak_secret一定不可存储在app代码中和移动端侧, 以防帐号信息泄露。
    //  若使用离线功能(离线语音合成), 则必须ak_id、ak_secret、app_key
    //  若使用在线功能(语音合成、实时转写、一句话识别、录音文件转写), 则只需app_key和token

    //用户申请阿里云账号和appkey后填入才可使用。
    //  ak_id ak_secret app_key如何获得,请查看https://help.aliyun.com/document_detail/72138.html
    NSString *ak_id = @"<一定不可代码中存储和本地明文存储>";
    NSString *ak_secret = @"<一定不可代码中存储和本地明文存储>";
    NSString *app_key = @"<您申请创建的app_key>";
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

    //郑重提示:
    //  您的账号信息ak_id和ak_secret一定不可存储在app代码中和移动端侧, 以防帐号信息泄露。
    //  若使用离线功能(离线语音合成), 则必须ak_id、ak_secret、app_key
    //  若使用在线功能(语音合成、实时转写、一句话识别、录音文件转写), 则只需app_key和token

    //账号和项目创建
    //  ak_id ak_secret app_key如何获得,请查看https://help.aliyun.com/document_detail/72138.html
    NSString *app_key = @"<您申请创建的app_key>"; // 必填
    [dictM setObject:app_key forKey:@"app_key"]; // 必填

    //请使用您的阿里云账号与appkey进行访问, 以下介绍两种方案(不限于两种)
    //方案一(强烈推荐):
    //  首先ak_id ak_secret app_key如何获得,请查看https://help.aliyun.com/document_detail/72138.html
    //  然后请看 https://help.aliyun.com/document_detail/466615.html 使用其中方案二使用STS获取临时账号
    //  此方案简介: 远端服务器运行STS生成具有有效时限的临时凭证, 下发给移动端进行使用, 保证账号信息ak_id和ak_secret不被泄露
    NSString *ak_id = @"STS.<服务器生成的具有时效性的临时凭证>"; // 必填
    NSString *ak_secret = @"<服务器生成的具有时效性的临时凭证>"; // 必填
    NSString *sts_token = @"<服务器生成的具有时效性的临时凭证>"; // 必填
    [dictM setObject:ak_id forKey:@"ak_id"]; // 必填
    [dictM setObject:ak_secret forKey:@"ak_secret"]; // 必填
    [dictM setObject:sts_token forKey:@"sts_token"]; // 必填

    //方案二(泄露风险, 不推荐):
    //  首先ak_id ak_secret app_key如何获得,请查看https://help.aliyun.com/document_detail/72138.html
    //  此方案简介: 远端服务器存储帐号信息, 加密下发给移动端进行使用, 保证账号信息ak_id和ak_secret不被泄露
//    NSString *ak_id = @"<一定不可代码中存储和本地明文存储>"; // 必填
//    NSString *ak_secret = @"<一定不可代码中存储和本地明文存储>"; // 必填
//    [dictM setObject:ak_id forKey:@"ak_id"]; // 必填
//    [dictM setObject:ak_secret forKey:@"ak_secret"]; // 必填

    // 离线语音合成sdk_code取值：精品版为software_nls_tts_offline， 标准版为software_nls_tts_offline_standard
    // 离线语音合成账户和sdk_code可用于唤醒
    NSString *sdk_code = @"software_nls_tts_offline_standard"; // 必填
    [dictM setObject:sdk_code forKey:@"sdk_code"]; // 必填

    // 特别说明: 鉴权所用的id是由以下device_id，与手机内部的一些唯一码进行组合加密生成的。
    //   更换手机或者更换device_id都会导致重新鉴权计费。
    //   此外, 以下device_id请设置有意义且具有唯一性的id, 比如用户账号(手机号、IMEI等),
    //   传入相同或随机变换的device_id会导致鉴权失败或重复收费。
    //   NSString *id_string = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]; 并不能保证生成不变的device_id，请不要使用
    [dictM setObject:@"empty_device_id" forKey:@"device_id"]; // 必填
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
