#import <Cordova/CDVInvokedUrlCommand.h>
#import <AdSupport/AdSupport.h>
#import "AliVoiceInteraction.h"
#import "NuiSdkUtils.h"

/********* AliVoiceInteraction.m Cordova Plugin Implementation *******/

@implementation AliVoiceInteraction

- (void)initialize:(CDVInvokedUrlCommand *)command {
    // 工具类和委托
    NSMutableDictionary *message = command.arguments[0];

    NSLog(@"%@", message[@"appKey"]);

    NSLog(@"%@", message[@"token"]);

    _voiceRecorder = [[NlsVoiceRecorder alloc] init];

    _voiceRecorder.delegate = self;

    _utils = [NuiSdkUtils alloc];

    //SDK 初始化区域
    NSData *data = [NSJSONSerialization dataWithJSONObject:message[@"params"] options:NSJSONWritingPrettyPrinted error:nil];

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];


    if (_nui == nil) {

        _nui = [NeoNui alloc];

        _nui.delegate = self;
    }

    //请注意此处的参数配置，其中账号相关需要在Utils.m getTicket 方法中填入后才可访问服务
    NSString *initParam = [self genInitParams:message[@"appKey"] token:message[@"token"]];

    [_nui nui_initialize:[initParam UTF8String] logLevel:LOG_LEVEL_VERBOSE saveLog:save_log];

    [_nui nui_set_params:[jsonStr UTF8String]];

    //返回区域
    CDVPluginResult *pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [pluginResult setKeepCallback:@(true)];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

- (void)startDialog:(CDVInvokedUrlCommand *)command {

    NSMutableDictionary *message = command.arguments[0];

    NSData *data = [NSJSONSerialization dataWithJSONObject:message[@"params"] options:NSJSONWritingPrettyPrinted error:nil];

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    _startDialogCallbackId = command.callbackId;



    CDVPluginResult *pluginResult = nil;

    if (_nui != nil) {

        [_nui nui_dialog_start:MODE_P2T dialogParam:[jsonStr UTF8String]];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

        TLog(@"in StartButHandler no nui alloc");
    }


    [pluginResult setKeepCallback:@(true)];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopDialog:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = nil;
    self.recordedVoiceData = nil;
    if (_nui != nil) {
        [_nui nui_dialog_cancel:NO];
        [_voiceRecorder stop:YES];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        TLog(@"in StopButHandler no nui alloc");
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)release:(CDVInvokedUrlCommand *)command {
    //释放sdk。
    [_nui nui_release];
}

- (NSString *)genInitParams:(NSString *)appKey token:(NSString *)token {
    NSString *strResourcesBundle = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
    NSString *bundlePath = [[NSBundle bundleWithPath:strResourcesBundle] resourcePath];
    NSString *id_string = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSString *debug_path = [_utils createDir];

    NSMutableDictionary *dictM = [NSMutableDictionary dictionary];

    dictM[@"workspace"] = bundlePath;
    dictM[@"debug_path"] = debug_path;
    dictM[@"device_id"] = id_string;
    dictM[@"save_wav"] = save_wav ? @"true" : @"false";

    //从阿里云获取appkey和token进行语音服务访问
    dictM[@"app_key"] = appKey;
    dictM[@"token"] = token;

    //由于token 24小时过期，可以参考getTicket实现从阿里云服务动态获取
    //[_utils getTicket:dictM];
    dictM[@"url"] = @"wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1";

    NSData *data = [NSJSONSerialization dataWithJSONObject:dictM options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonStr;
}

#pragma mark - Voice Recorder Delegate

- (void)recorderDidStart {
    TLog(@"recorderDidStart");
}

- (void)recorderDidStop {
    [self.recordedVoiceData setLength:0];
    TLog(@"recorderDidStop");
}

- (void)voiceRecorded:(NSData *)frame {
    @synchronized (_recordedVoiceData) {
        [_recordedVoiceData appendData:frame];
    }
}

- (void)voiceDidFail:(NSError *)error {
    TLog(@"recorder error ");
}

#pragma mark - Nui Listener

- (void)onNuiEventCallback:(NuiCallbackEvent)nuiEvent
                    dialog:(long)dialog
                 kwsResult:(const char *)wuw
                 asrResult:(const char *)asr_result
                  ifFinish:(bool)finish
                   retCode:(int)code {
//    TLog(@"onNuiEventCallback event %d finish %d", nuiEvent, finish);

    NSNumber *kwsResultNumber = [NSNumber numberWithLong:wuw];

    NSString *kwsResultStr = [kwsResultNumber stringValue];

    NSMutableDictionary *mDict = [[NSMutableDictionary alloc] init];

    mDict[@"name"] = @"AliVoiceInteraction.nuiEventCallback";

    mDict[@"nuiEvent"] = [self NSStringFromTransactionState:nuiEvent];

    mDict[@"kwsResult"] = kwsResultStr;

    mDict[@"finish"] = finish ? @"true" : @"false";

    if (asr_result) {
        mDict[@"asrResult"] = [NSString stringWithUTF8String:asr_result];
    }

    [self sendPluginResultAli:self.startDialogCallbackId mDict:mDict];

}

- (int)onNuiNeedAudioData:(char *)audioData length:(int)len {
    TLog(@"onNuiNeedAudioData");
    static int emptyCount = 0;
    @autoreleasepool {
        @synchronized (_recordedVoiceData) {
            if (_recordedVoiceData.length > 0) {
                int recorder_len = 0;
                if (_recordedVoiceData.length > len)
                    recorder_len = len;
                else
                    recorder_len = _recordedVoiceData.length;
                NSData *tempData = [_recordedVoiceData subdataWithRange:NSMakeRange(0, recorder_len)];
                [tempData getBytes:audioData length:recorder_len];
                tempData = nil;
                NSInteger remainLength = _recordedVoiceData.length - recorder_len;
                NSRange range = NSMakeRange(recorder_len, remainLength);
                [_recordedVoiceData setData:[_recordedVoiceData subdataWithRange:range]];
                emptyCount = 0;
                return recorder_len;
            } else {
                if (emptyCount++ >= 50) {
                    TLog(@"_recordedVoiceData length = %lu! empty 50times.", (unsigned long) _recordedVoiceData.length);
                    emptyCount = 0;
                }
                return 0;
            }

        }
    }
    return 0;
}

- (void)onNuiAudioStateChanged:(NuiAudioState)state {
    TLog(@"onNuiAudioStateChanged state=%u", state);
    if (state == STATE_CLOSE || state == STATE_PAUSE) {
        [_voiceRecorder stop:YES];
    } else if (state == STATE_OPEN) {
        self.recordedVoiceData = [NSMutableData data];
        [_voiceRecorder start];
    }
}

- (void)onNuiRmsChanged:(float)rms {
    TLog(@"onNuiRmsChanged rms=%f", rms);

    NSMutableDictionary *mDict = [[NSMutableDictionary alloc] init];

    NSNumber *rmsNumber = [NSNumber numberWithLong:rms];

    NSString *rmsStr = [rmsNumber stringValue];

    mDict[@"name"] = @"AliVoiceInteraction.nuiAudioRMSChanged";

    mDict[@"vol"] = rmsStr;

    [self sendPluginResultAli:self.startDialogCallbackId mDict:mDict];
}


#pragma sendPluginResult

- (void)sendPluginResultAli:(NSString *)callbackId mDict:(NSMutableDictionary *)mDict {

    CDVPluginResult *pluginResult = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:mDict];

    [pluginResult setKeepCallback:@(true)];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (NSString *)NSStringFromTransactionState:(NuiCallbackEvent)state {
    switch (state) {
        case EVENT_VAD_START:
            return @"EVENT_VAD_START";
        case EVENT_VAD_TIMEOUT:
            return @"EVENT_VAD_TIMEOUT";
        case EVENT_VAD_END:
            return @"EVENT_VAD_END";
        case EVENT_WUW:
            return @"EVENT_WUW";
        case EVENT_WUW_TRUSTED:
            return @"EVENT_WUW_TRUSTED";
        case EVENT_WUW_CONFIRMED:
            return @"EVENT_WUW_CONFIRMED";
        case EVENT_WUW_REJECTED:
            return @"EVENT_WUW_REJECTED";
        case EVENT_WUW_END:
            return @"EVENT_WUW_END";
        case EVENT_ASR_PARTIAL_RESULT:
            return @"EVENT_ASR_PARTIAL_RESULT";
        case EVENT_ASR_RESULT:
            return @"EVENT_ASR_RESULT";
        case EVENT_ASR_ERROR:
            return @"EVENT_ASR_ERROR";
        case EVENT_DIALOG_ERROR:
            return @"EVENT_DIALOG_ERROR";
        case EVENT_ONESHOT_TIMEOUT:
            return @"EVENT_ONESHOT_TIMEOUT";
        case EVENT_DIALOG_RESULT:
            return @"EVENT_DIALOG_RESULT";
        case EVENT_WUW_HINT:
            return @"EVENT_WUW_HINT";
        case EVENT_VPR_RESULT:
            return @"EVENT_VPR_RESULT";
        case EVENT_TEXT2ACTION_DIALOG_RESULT:
            return @"EVENT_TEXT2ACTION_DIALOG_RESULT";
        case EVENT_TEXT2ACTION_ERROR:
            return @"EVENT_TEXT2ACTION_ERROR";
        case EVENT_ATTR_RESULT:
            return @"EVENT_ATTR_RESULT";
        case EVENT_MIC_ERROR:
            return @"EVENT_MIC_ERROR";
        case EVENT_DIALOG_EX:
            return @"EVENT_DIALOG_EX";
        case EVENT_WUW_ERROR:
            return @"EVENT_WUW_ERROR";
        case EVENT_BEFORE_CONNECTION:
            return @"EVENT_BEFORE_CONNECTION";
        case EVENT_SENTENCE_START:
            return @"EVENT_SENTENCE_START";
        case EVENT_SENTENCE_END:
            return @"EVENT_SENTENCE_END";
        case EVENT_SENTENCE_SEMANTICS:
            return @"EVENT_SENTENCE_SEMANTICS";
        case EVENT_TRANSCRIBER_COMPLETE:
            return @"EVENT_TRANSCRIBER_COMPLETE";
        case EVENT_FILE_TRANS_CONNECTED:
            return @"EVENT_FILE_TRANS_CONNECTED";
        case EVENT_FILE_TRANS_UPLOADED:
            return @"EVENT_FILE_TRANS_UPLOADED";
        case EVENT_FILE_TRANS_RESULT:
            return @"EVENT_FILE_TRANS_RESULT";
        case EVENT_FILE_TRANS_UPLOAD_PROGRESS:
            return @"EVENT_FILE_TRANS_UPLOAD_PROGRESS";
        default:
            return @"ERROR";

    }
}


@end
