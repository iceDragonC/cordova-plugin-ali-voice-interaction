#import <Cordova/CDV.h>
#import <nuisdk/NeoNui.h>
#import "NLSVoiceRecorder.h"

@class NlsVoiceRecorder;
@class NuiSdkUtils;
static BOOL save_wav = NO;
static BOOL save_log = NO;
@interface AliVoiceInteraction : CDVPlugin<NeoNuiSdkDelegate, NlsVoiceRecorderDelegate> {
    // Member variables go here.
}

@property(nonatomic,strong) NeoNui* nui;

@property(nonatomic,strong) NlsVoiceRecorder *voiceRecorder;

@property(nonatomic,strong) NSMutableData *recordedVoiceData;

@property(nonatomic,strong) NuiSdkUtils *utils;

@property (nonatomic, strong) NSString* startDialogCallbackId;

- (void)initialize:(CDVInvokedUrlCommand *)command;

- (void)startDialog:(CDVInvokedUrlCommand*)command;

- (void)stopDialog:(CDVInvokedUrlCommand*)command;

- (void)release:(CDVInvokedUrlCommand*)command;

@end