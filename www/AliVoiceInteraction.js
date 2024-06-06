let exec = require('cordova/exec');

const aliVoiceInteractionName = "AliVoiceInteraction";
const errorText = "返回值不存在";
const jsonErrorText = "JSON格式错误";

let AliVoiceInteraction = {
    /**
     * 初始化SDK
     * @param args
     * @param success
     * @param error
     * @version 1.0.0
     */
    initialize(args, success, error) {
        exec(success, error, aliVoiceInteractionName, 'initialize', [args]);
    },
    /**
     * 设置参数
     * @param args
     * @param success
     * @param error
     * @version 1.0.0
     */

    setParams(args, success, error) {
        exec(success, error, aliVoiceInteractionName, 'setParams', [args]);
    },
    /**
     * 开始识别
     * @param args
     * @param success
     * @param error
     * @version 1.0.0
     */
    startDialog(args, success, error) {
        exec(success, error, aliVoiceInteractionName, 'startDialog', [args]);
    },
    /**
     * 停止识别
     * @param success
     * @param error
     * @version 1.0.0
     */
    stopDialog(success, error) {
        exec(success, error, aliVoiceInteractionName, 'stopDialog', []);
    },

    /**
     * 释放SDK
     * @param success
     * @param error
     * @version 1.0.0
     */
    release(success, error) {
        exec(success, error, aliVoiceInteractionName, 'release', []);
    },

    /**
     * SDK 方法请勿调用
     * @param contentJson
     */
    nuiAudioStateChanged(contentJson) {
        let content = null;
        let respEvent = new CustomEvent('nuiAudioStateChangedEvent', {
            'detail': {  //可携带额外的数据
                message: null
            },
            'bubbles': true,//是否冒泡    回调函数中调用，e.stopPropagation();可以阻止冒泡
            'cancelable': false,//是否可以取消  为true时，event.preventDefault();才可以阻止默认动作行为
        });
        try {
            content = JSON.parse(contentJson);
            respEvent.detail.message = content;
            window.dispatchEvent(respEvent);
        } catch (e) {
            throw new Error(jsonErrorText);
        }
    },
    /**
     * SDK 方法请勿调用
     * @param contentJson
     */
    nuiNeedAudioData(contentJson) {
        let content = null;
        let respEvent = new CustomEvent('nuiNeedAudioDataEvent', {
            'detail': {  //可携带额外的数据
                message: null
            },
            'bubbles': true,//是否冒泡    回调函数中调用，e.stopPropagation();可以阻止冒泡
            'cancelable': false,//是否可以取消  为true时，event.preventDefault();才可以阻止默认动作行为
        });
        try {
            content = JSON.parse(contentJson);
            respEvent.detail.message = content;
            window.dispatchEvent(respEvent);
        } catch (e) {
            throw new Error(jsonErrorText);
        }
    },
    /**
     * SDK 方法请勿调用
     * @param contentJson
     */
    nuiEventCallback(contentJson) {
        let content = null;
        let respEvent = new CustomEvent('nuiEventCallbackEvent', {
            'detail': {  //可携带额外的数据
                message: null
            },
            'bubbles': true,//是否冒泡    回调函数中调用，e.stopPropagation();可以阻止冒泡
            'cancelable': false,//是否可以取消  为true时，event.preventDefault();才可以阻止默认动作行为
        });
        try {
            content = JSON.parse(contentJson);
            respEvent.detail.message = content;
            window.dispatchEvent(respEvent);
        } catch (e) {
            throw new Error(jsonErrorText);
        }
    },
    /**
     * SDK 方法请勿调用
     * @param contentJson
     */
    nuiAudioRMSChanged(contentJson) {
        let content = null;
        let respEvent = new CustomEvent('nuiAudioRMSChangedEvent', {
            'detail': {  //可携带额外的数据
                message: null
            },
            'bubbles': true,//是否冒泡    回调函数中调用，e.stopPropagation();可以阻止冒泡
            'cancelable': false,//是否可以取消  为true时，event.preventDefault();才可以阻止默认动作行为
        });
        try {
            content = JSON.parse(contentJson);
            respEvent.detail.message = content;
            window.dispatchEvent(respEvent);
        } catch (e) {
            throw new Error(jsonErrorText);
        }
    },

    /**
     * 当start/stop/cancel等接口调用时，SDK通过此回调通知App进行录音的开关操作。
     * @param success
     * @param error
     * @version 1.0.0
     */
    onNuiAudioStateChanged: (success, error) => {
        window.addEventListener("nuiAudioStateChangedEvent", (e) => {
            try {
                success(e.detail.message);
            } catch (e) {
                error(errorText);
            }
        });
    },


    /**
     * 录音数据回调，在该回调中填充录音数据。
     * @param success
     * @param error
     * @version 1.0.0
     */
    onNuiNeedAudioData: (success, error) => {
        window.addEventListener("nuiNeedAudioDataEvent", (e) => {
            try {
                success(e.detail.message);
            } catch (e) {
                error(errorText);
            }
        });
    },
    /**
     * SDK主要事件回调
     * @param success
     * @param error
     * @version 1.0.0
     */
    onNuiEventCallback: (success, error) => {
        window.addEventListener("nuiEventCallbackEvent", (e) => {
            try {
                success(e.detail.message);
            } catch (e) {
                error(errorText);
            }
        });
    },
    /**
     *  音频数据能量值回调，范围-160至0，一般用于UI展示语音动效
     * @param success
     * @param error
     * @version 1.0.0
     */
    onNuiAudioRMSChanged: (success, error) => {
        window.addEventListener("nuiAudioRMSChangedEvent", (e) => {
            try {
                success(e.detail.message);
            } catch (e) {
                error(errorText);
            }
        });
    },

}
module.exports = AliVoiceInteraction;
