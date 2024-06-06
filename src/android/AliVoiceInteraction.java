package ali.voice.interaction;

import android.Manifest;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.util.Log;

import com.alibaba.idst.nui.AsrResult;
import com.alibaba.idst.nui.CommonUtils;
import com.alibaba.idst.nui.Constants;
import com.alibaba.idst.nui.INativeNuiCallback;
import com.alibaba.idst.nui.KwsResult;
import com.alibaba.idst.nui.NativeNui;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class AliVoiceInteraction extends CordovaPlugin implements INativeNuiCallback {

  private static final String TAG = "AliVoiceInteraction";

  NativeNui nui_instance = null;

  private String[] permissions = {Manifest.permission.RECORD_AUDIO};

  final static int WAVE_FRAM_SIZE = 20 * 2 * 1 * 16000 / 1000; //20ms audio for 16k/16bit/mono

  public final static int SAMPLE_RATE = 16000;

  private AudioRecord mAudioRecorder;

  private CallbackContext startDialogCallbackContext;


  private boolean mInit = false;

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    try {
      if (action.equals("initialize")) {
        JSONObject jsonObject = args.getJSONObject(0);
        this.initialize(jsonObject);
        callbackContext.success();
        return true;
      }
      if (action.equals("startDialog")) {
        JSONObject jsonObject = args.getJSONObject(0);
        this.startDialog(jsonObject);
        startDialogCallbackContext = callbackContext;
        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
        pluginResult.setKeepCallback(true);
        startDialogCallbackContext.sendPluginResult(pluginResult);
        return true;
      }
      if (action.equals("stopDialog")) {
        this.stopDialog();
        callbackContext.success();
        return true;
      }
      if (action.equals("release")) {
        this.release();
        callbackContext.success();
        return true;
      }
    } catch (JSONException jsonException) {
      JSONObject errorJson = new JSONObject();
      errorJson.put("code", "500");
      errorJson.put("errorInfo", "参数非法");
      callbackContext.error(errorJson);
      return true;
    } catch (Exception runtimeException) {
      JSONObject errorJson = new JSONObject();
      errorJson.put("code", "500");
      errorJson.put("errorInfo", runtimeException.getMessage());
      callbackContext.error(errorJson);
      return true;
    }
    return false;
  }

  private void initialize(JSONObject jsonObject) throws JSONException, RuntimeException {
    nui_instance = new NativeNui();
    //录音初始化，录音参数中格式只支持16bit/单通道，采样率支持8K/16K
    mAudioRecorder = new AudioRecord(MediaRecorder.AudioSource.DEFAULT, SAMPLE_RATE,
      AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, WAVE_FRAM_SIZE * 4);

    //获取工作路径
    String assets_path = CommonUtils.getModelPath(cordova.getActivity());
    Log.i(TAG, "use workspace " + assets_path);

    String debug_path = cordova.getActivity().getExternalCacheDir().getAbsolutePath() + "/debug_" + System.currentTimeMillis();
    Utils.createDir(debug_path);

    //拷贝资源
    CommonUtils.copyAssetsData(cordova.getActivity());
    //SDK初始化
    //初始化SDK，注意用户需要在Auth.getAliYunTicket中填入相关ID信息才可以使用。
    int ret = nui_instance.initialize(this, genInitParams(assets_path, debug_path, jsonObject.getString("appKey"), jsonObject.getString("token")), Constants.LogLevel.LOG_LEVEL_VERBOSE, true);

    if (ret == Constants.NuiResultCode.SUCCESS) {
      this.mInit = true;
    } else {
      throw new RuntimeException("未初始化");
    }
    //设置相关识别参数，具体参考API文档
    nui_instance.setParams(jsonObject.getJSONObject("params").toString());
    Log.d("传值的String", jsonObject.getJSONObject("params").toString());
    Log.d("生成的String", genParams());
  }

  private String genParams() {
    String params = "";
    try {
      com.alibaba.fastjson.JSONObject nls_config = new com.alibaba.fastjson.JSONObject();
      nls_config.put("enable_intermediate_result", true);
//            参数可根据实际业务进行配置
      nls_config.put("enable_punctuation_prediction", true);
//            nls_config.put("enable_inverse_text_normalization", true);
//            nls_config.put("enable_voice_detection", true);
//            nls_config.put("customization_id", "test_id");
//            nls_config.put("vocabulary_id", "test_id");
//            nls_config.put("max_start_silence", 10000);
//            nls_config.put("max_end_silence", 800);
//            nls_config.put("sample_rate", 16000);
//            nls_config.put("sr_format", "opus");
      com.alibaba.fastjson.JSONObject parameters = new com.alibaba.fastjson.JSONObject();

      parameters.put("nls_config", nls_config);
      parameters.put("service_type", Constants.kServiceTypeASR);
//            如果有HttpDns则可进行设置
//            parameters.put("direct_ip", Utils.getDirectIp());
      params = parameters.toString();
    } catch (com.alibaba.fastjson.JSONException e) {
      e.printStackTrace();
    }
    return params;
  }

  private String genInitParams(String workPath, String debugPath, String appKey, String token) throws JSONException {
    JSONObject object = new JSONObject();
    object.put("app_key", appKey);
    object.put("token", token);
    object.put("device_id", Utils.getDeviceId());
    object.put("url", "wss://nls-gateway.cn-shanghai.aliyuncs.com:443/ws/v1");
    object.put("workspace", workPath);
    object.put("debug_path", debugPath);
    return object.toString();
  }


  public void startDialog(JSONObject jsonObject) throws JSONException {
    if (this.mInit) {
      nui_instance.startDialog(Constants.VadMode.TYPE_P2T, jsonObject.getJSONObject("params").toString());
    }
  }

  public void stopDialog() {
    nui_instance.stopDialog();
  }

  public void release() {
    nui_instance.release();
    this.mInit = false;
    nui_instance = null;
  }

  private void checkPermissions() throws Exception {
    cordova.requestPermissions(this, 500, permissions);
    for (String perm : permissions) {
      if (!cordova.hasPermission(perm)) {
        throw new Exception("未开启录音权限！");
      }
    }
  }

  @Override
  public void onNuiEventCallback(Constants.NuiEvent nuiEvent, int i, int i1, KwsResult kwsResult, AsrResult asrResult) {
//    Log.i(TAG, "event=" + nuiEvent);
    try {
      //
      JSONObject jsonObj = new JSONObject();

      JSONObject asrResultObj = new JSONObject();

      if (asrResult != null) {

        jsonObj.put("finish", asrResult.finish);

        asrResultObj.put("resultCode", asrResult.resultCode);

        JSONObject asrResultAsrResultObj = new JSONObject();
        try {
          asrResultAsrResultObj = new JSONObject(asrResult.asrResult);

        } catch (JSONException e) {

          asrResultAsrResultObj.put("asrResult", asrResult.asrResult);

        }
        asrResultObj.put("asrResult", asrResultAsrResultObj);
      }


      jsonObj.put("nuiEvent", nuiEvent);

      jsonObj.put("kwsResult", kwsResult);

      jsonObj.put("asrResult", asrResultObj);

      Log.d("jsonObj", jsonObj.toString());

      send("AliVoiceInteraction.nuiEventCallback", jsonObj);

    } catch (JSONException e) {
      e.printStackTrace();
    }

  }

  @Override
  public int onNuiNeedAudioData(byte[] bytes, int i) {
    int ret = 0;
    if (mAudioRecorder.getState() != AudioRecord.STATE_INITIALIZED) {
      Log.e(TAG, "audio recorder not init");
      return -1;
    }
    ret = mAudioRecorder.read(bytes, 0, i);
    return ret;
  }

  @Override
  public void onNuiAudioStateChanged(Constants.AudioState audioState) {
    Log.i(TAG, "onNuiAudioStateChanged");
    try {
      if (audioState == Constants.AudioState.STATE_OPEN) {
        Log.i(TAG, "audio recorder start");
        mAudioRecorder.startRecording();
        Log.i(TAG, "audio recorder start done");
      } else if (audioState == Constants.AudioState.STATE_CLOSE) {
        Log.i(TAG, "audio recorder close");
        mAudioRecorder.release();
      } else if (audioState == Constants.AudioState.STATE_PAUSE) {
        Log.i(TAG, "audio recorder pause");
        mAudioRecorder.stop();
      }
    } catch (Exception e) {
      e.printStackTrace();
    }

  }

  @Override
  public void onNuiAudioRMSChanged(float v) {

    Log.i(TAG, "onNuiAudioRMSChanged vol " + v);

    JSONObject jsonObject = new JSONObject();
    try {
      jsonObject.put("vol", v);
      send("AliVoiceInteraction.nuiAudioRMSChanged", jsonObject);
    } catch (JSONException e) {
      e.printStackTrace();
    }
  }

  @Override
  public void onNuiVprEventCallback(Constants.NuiVprEvent nuiVprEvent) {
    Log.i(TAG, "onNuiVprEventCallback event " + nuiVprEvent);
  }

  public void send(String name, JSONObject jsonObject) throws JSONException {
//    webView.getView().post(new Runnable() {
//      @Override
//      public void run() {
//        webView.loadUrl("javascript: " + name + "('" + jsonObject.toString() + "')");
//      }
//    });
    //设置name
    jsonObject.put("name", name);
    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, jsonObject);
    pluginResult.setKeepCallback(true);
    startDialogCallbackContext.sendPluginResult(pluginResult);
  }

}
