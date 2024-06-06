//
//  Utils.h
//  NUIdemo
//
//  Created by zhouguangdong on 2019/12/26.
//  Copyright © 2019 Alibaba idst. All rights reserved.
//

#ifndef NuiSdkUtils_h
#define NuiSdkUtils_h
#ifdef DEBUG_MODE
#define TLog( s, ... ) NSLog( s, ##__VA_ARGS__ )
#else
#define TLog( s, ... )
#endif
#import <Foundation/Foundation.h>
@interface NuiSdkUtils : NSObject
-(NSString *)dirDoc;

//create dir for saving files
-(NSString *)createDir;

-(NSString*) genInitParams;

-(void) getTicket:(NSMutableDictionary*) dict;

-(void) getAuthTicket:(NSMutableDictionary*) dict;

-(NSString*) getDirectIp;

-(NSString*) generateToken:(NSString*)accessKey withSecret:(NSString*)accessSecret;
@end
#endif /* NuiSdkUtils_h */
