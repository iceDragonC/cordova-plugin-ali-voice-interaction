package ali.voice.interaction;

import android.os.Build;
import android.text.TextUtils;
import android.util.Log;

import java.io.File;
import java.net.InetAddress;
import java.net.UnknownHostException;

public class Utils {
  private static final String TAG = "DemoUtils";
  public static String ip = "";
  public static int createDir (String dirPath) {
    File dir = new File(dirPath);
    //文件夹是否已经存在
    if (dir.exists()) {
      Log.w(TAG,"The directory [ " + dirPath + " ] has already exists");
      return 1;
    }

    if (!dirPath.endsWith(File.separator)) {//不是以 路径分隔符 "/" 结束，则添加路径分隔符 "/"
      dirPath = dirPath + File.separator;
    }

    //创建文件夹
    if (dir.mkdirs()) {
      Log.d(TAG,"create directory [ "+ dirPath + " ] success");
      return 0;
    }

    Log.e(TAG,"create directory [ "+ dirPath + " ] failed");
    return -1;
  }

  /** Returns the consumer friendly device name */
  public static String getDeviceName() {
    String manufacturer = Build.MANUFACTURER;
    String model = Build.MODEL;
    if (model.startsWith(manufacturer)) {
      return capitalize(model);
    }
    return capitalize(manufacturer) + " " + model;
  }

  public static String getDeviceId() {
    return android.os.Build.SERIAL;
  }

  public static String getDirectIp() {
    Log.i(TAG, "direct ip is " + Utils.ip);
    Thread th = new Thread(){
      @Override
      public void run() {
        try {
          InetAddress addr = InetAddress.getByName("nls-gateway-inner.aliyuncs.com");
          Utils.ip = addr.getHostAddress();
          Log.i(TAG, "direct ip is " + Utils.ip);
        } catch (UnknownHostException e) {
          e.printStackTrace();
        }
      }

    };
    th.start();
    try {
      th.join(5000);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
    return ip;
  }


  private static String capitalize(String str) {
    if (TextUtils.isEmpty(str)) {
      return str;
    }
    char[] arr = str.toCharArray();
    boolean capitalizeNext = true;

    StringBuilder phrase = new StringBuilder();
    for (char c : arr) {
      if (capitalizeNext && Character.isLetter(c)) {
        phrase.append(Character.toUpperCase(c));
        capitalizeNext = false;
        continue;
      } else if (Character.isWhitespace(c)) {
        capitalizeNext = true;
      }
      phrase.append(c);
    }

    return phrase.toString();
  }
}

