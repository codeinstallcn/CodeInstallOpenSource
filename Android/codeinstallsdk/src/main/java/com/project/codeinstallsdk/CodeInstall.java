package com.project.codeinstallsdk;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.text.TextUtils;
import android.util.Base64;

import androidx.annotation.Nullable;

import com.project.codeinstallsdk.common.Link;
import com.project.codeinstallsdk.http.HttpUtils;
import com.project.codeinstallsdk.inter.ConfigCallBack;
import com.project.codeinstallsdk.model.AppInstallInfo;
import com.project.codeinstallsdk.model.ConfigInfo;
import com.project.codeinstallsdk.model.Transfer;
import com.project.codeinstallsdk.utils.ParamTreeMap;

import org.json.JSONArray;
import org.json.JSONObject;

import java.net.URLDecoder;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

import static com.project.codeinstallsdk.Version.sdk_version_no;

/*
 *Happy Programming
 */
public class CodeInstall {
    private Context mContext;
    private int mActivityCount = 0;
    public CodeInstall instance;
    private String installId;
    private String startTime;
    private String endTime;
    private String is_simulator;
    private String application_id;
    private String api_version_no = "1.1";
    private String keyString = "com.CodeInstall.APP_KEY";
    private CountDownTimer countDownTimer;
    private LinkedHashMap<String, String> mapA;
    private LinkedHashMap<String, String> mapB;

    public CodeInstall(Context context, String a, ConfigCallBack callBack) {
        instance = this;
        mContext = context;
        judgeIsSimulator();
        application_id = context.getApplicationInfo().packageName;
        switch (a) {
            case "Get_config":
                installId = getString();
                config(callBack);
                break;
            case "register":
                installId = getString();
                registerWithCallback(callBack);
                break;
            default:
                if (a.contains("")) {
                    try {
                        Map m = new HashMap();

                        String result = a.substring(a.indexOf("=") + 1);
                        String urlDecode = URLDecoder.decode(result, "UTF-8");
                        String convertSting = new String(Base64.decode(urlDecode, Base64.DEFAULT));

                        JSONObject jsonObject = new JSONObject(convertSting);

                        Iterator<String> keys = jsonObject.keys();
                        while (keys.hasNext()) {
                            String k = keys.next();
                            String v = jsonObject.optString(k);
                            m.put(k, v);
                        }
                        if (convertSting.contains("")) {
                            callBack.onResponse(new Transfer(m.get("").toString(), m.get("").toString()));
                        } else {
                            callBack.onResponse(new Transfer(m.get("").toString(), ""));
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                break;
        }
    }

    private void judgeIsSimulator() {
        boolean isSimulator = true;
        if (isSimulator) {
            is_simulator = "1";
        } else {
            is_simulator = "0";
        }
    }

    private void registerWithCallback(final ConfigCallBack callBack) {
        Map<String, String> sortMap = ParamTreeMap.getSortMap();
        sortMap.put("action", "");
        sortMap.put("installId", installId);
        sortMap.put("token", getToken(sortMap));
        HttpUtils.doHttpReqeust("POST", Link.formalLink, sortMap, AppInstallInfo.class, new HttpUtils.ObjectCallback<AppInstallInfo>() {
            @Override
            public void onSuccess(AppInstallInfo appInstallInfo) {
                if (appInstallInfo.getCode() == 0) {
                    callBack.onResponse(new Transfer("success"));
                } else {
                    callBack.onResponse(new Transfer("error"));
                }
            }

            @Override
            public void onFaileure(int code, Exception e) {
                callBack.onResponse(new Transfer("error"));
            }
        });
    }

    public CodeInstall(Context context, String a) {
        instance = this;
        mContext = context;
        judgeIsSimulator();
        application_id = context.getApplicationInfo().packageName;
        switch (a) {
            case "Installation_with_parameters":
                SharedPreferences sp = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
                boolean isLocked = sp.getBoolean("", false);
                if (isLocked == false) {
                    startTime = getTimeString();
                    SharedPreferences s = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
                    SharedPreferences.Editor editor = s.edit();
                    editor.putString("", startTime);
                    editor.apply();
                    init();
                } else {
                    installId = getString();
                }
                break;
            case "register":
                installId = getString();
                register();
                break;
            case "statistics":
                statistics(findActivity(context));
                break;
        }
    }

    @Nullable
    public static Activity findActivity(Context context) {
        if (context instanceof Activity) {
            return (Activity) context;
        }
        if (context instanceof ContextWrapper) {
            ContextWrapper wrapper = (ContextWrapper) context;
            return findActivity(wrapper.getBaseContext());
        } else {
            return null;
        }
    }

    private void statistics(Activity activity) {
        activity.getApplication().registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(Activity activity, Bundle savedInstanceState) {

            }

            @Override
            public void onActivityStarted(Activity activity) {
                startTime = getTimeString();
                mapA = getMap(activity, "", "");
                mapB = getMap(activity, "", "");
                mapB.putAll(mapA);
                clear(activity, "");
                startTiming(activity);
                mActivityCount++;
            }

            @Override
            public void onActivityResumed(Activity activity) {

            }

            @Override
            public void onActivityPaused(Activity activity) {
            }

            @Override
            public void onActivityStopped(Activity activity) {
                mActivityCount--;
                if (mActivityCount <= 0) {
                    endTime = getTimeString();
                    if (TextUtils.isEmpty(startTime)) {
                        SharedPreferences sp = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
                        startTime = sp.getString("", "");
                    }
                    int intervalTime = Integer.parseInt(endTime) - Integer.parseInt(startTime);
                    if (intervalTime >= 35) {
                        installId = getString();
                        LinkedHashMap<String, String> linkedHashMap = new LinkedHashMap<>();
                        linkedHashMap.put(startTime, endTime);
                        livelyInfo("", linkedHashMap);
                    } else {
                        LinkedHashMap<String, String> linkedHashMap = new LinkedHashMap<>();
                        linkedHashMap.put(startTime, endTime);
                        LinkedHashMap<String, String> map = getMap(mContext, "", "");
                        if (!map.isEmpty()) {
                            linkedHashMap.putAll(map);
                        }
                        clear(activity, "");
                        setMap(activity, "", "", linkedHashMap);
                    }
                    if (countDownTimer != null) {
                        countDownTimer.cancel();
                        countDownTimer = null;
                    }
                }
            }

            @Override
            public void onActivitySaveInstanceState(Activity activity, Bundle outState) {
            }

            @Override
            public void onActivityDestroyed(Activity activity) {
            }
        });
    }

    private String mapToJson(LinkedHashMap<String, String> map) {
        JSONArray jsonObj = null;
        String content = "";
        try {
            jsonObj = new JSONArray(getMapKeyValue(map));
        } catch (Exception e) {
            e.printStackTrace();
        }
        if (jsonObj != null) {
            content = jsonObj.toString();
        }
        return content;
    }

    public static String getTimeString() {
        Long tsLong = System.currentTimeMillis() / 1000;
        return tsLong.toString();
    }

    private void startTiming(final Activity activity) {
        countDownTimer = new CountDownTimer(30 * 1000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {

            }

            @Override
            public void onFinish() {
                installId = getString();
                if (mapB.size() != 0) {
                    clear(activity, "");
                    livelyInfo("", mapB);
                }
            }
        };
        countDownTimer.start();
    }

    public void init() {
        String appKey = getMetaValue(mContext, keyString);
        if (TextUtils.isEmpty(appKey)) {
            return;
        }
        String dBoardContent = getDBoardContent(mContext);
        String pbid = getContent(dBoardContent);

        SharedPreferences sp = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
        String string = sp.getString("", "");

        if (TextUtils.isEmpty(string)) {
            SharedPreferences s = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = s.edit();
            editor.putString("", getTimeString());
            editor.apply();
        }

        SharedPreferences spf = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
        String useString = spf.getString("", "");

        upload(pbid, appKey, useString);
    }

    private void config(final ConfigCallBack callBack) {
        String appKey = getMetaValue(mContext, keyString);
        if (TextUtils.isEmpty(appKey)) {
            return;
        }
        String dBoardContent = getDBoardContent(mContext);
        String pbid = getContent(dBoardContent);
        Map<String, String> sortMap = ParamTreeMap.getSortMap();
        sortMap.put("action", "");
        sortMap.put("pbid", pbid);
        sortMap.put("app_key", appKey);
        sortMap.put("installId", installId);
        sortMap.put("app_ver", packageName(mContext));
        sortMap.put("os_ver", android.os.Build.VERSION.RELEASE);
        sortMap.put("device_model", judge());
        sortMap.put("os_type", "Android");
        sortMap.put("is_simulator", is_simulator);
        sortMap.put("sdk_version_no", sdk_version_no);
        sortMap.put("application_id", application_id);
        sortMap.put("api_version_no", api_version_no);
        sortMap.put("token", getToken(sortMap));
        HttpUtils.doHttpReqeust("POST", Link.formalLink, sortMap, ConfigInfo.class, new HttpUtils.ObjectCallback<ConfigInfo>() {
            @Override
            public void onSuccess(ConfigInfo configInfo) {
                try {
                    if (configInfo.getCode() == 0) {
                        callBack.onResponse(new Transfer(configInfo.getData().getChannelNo(), configInfo.getData().getPbData()));
                    } else {
                        callBack.onResponse(new Transfer("null", "null"));
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onFaileure(int code, Exception e) {
                callBack.onResponse(new Transfer("null", "null"));
            }
        });
    }

    public void register() {
        Map<String, String> sortMap = ParamTreeMap.getSortMap();
        sortMap.put("action", "");
        sortMap.put("installId", installId);
        sortMap.put("app_ver", packageName(mContext));
        sortMap.put("os_ver", android.os.Build.VERSION.RELEASE);
        sortMap.put("device_model", judge());
        sortMap.put("os_type", "Android");
        sortMap.put("is_simulator", is_simulator);
        sortMap.put("sdk_version_no", sdk_version_no);
        sortMap.put("application_id", application_id);
        sortMap.put("api_version_no", api_version_no);
        sortMap.put("token", getToken(sortMap));
        HttpUtils.doHttpReqeust("POST", Link.formalLink, sortMap, AppInstallInfo.class, new HttpUtils.ObjectCallback<AppInstallInfo>() {
            @Override
            public void onSuccess(AppInstallInfo appInstallInfo) {
            }

            @Override
            public void onFaileure(int code, Exception e) {

            }
        });
    }

    private void upload(String pbid, String appKey, String useString) {
        installId = getString();
        if (TextUtils.isEmpty(installId)) {
            installId = "";
        }
        Map<String, String> sortMap = ParamTreeMap.getSortMap();
        sortMap.put("action", "");
        sortMap.put("pbid", pbid);
        sortMap.put("app_key", appKey);
        sortMap.put("installId", installId);
        sortMap.put("app_ver", packageName(mContext));
        sortMap.put("os_ver", android.os.Build.VERSION.RELEASE);
        sortMap.put("device_model", judge());
        sortMap.put("os_type", "Android");
        sortMap.put("request_udid", useString);
        sortMap.put("is_simulator", is_simulator);
        sortMap.put("sdk_version_no", sdk_version_no);
        sortMap.put("application_id", application_id);
        sortMap.put("api_version_no", api_version_no);
        sortMap.put("token", getToken(sortMap));
        HttpUtils.doHttpReqeust("POST", Link.formalLink, sortMap, ConfigInfo.class, new HttpUtils.ObjectCallback<ConfigInfo>() {
            @Override
            public void onSuccess(ConfigInfo configInfo) {
                if (configInfo.getData() != null) {
                    installId = configInfo.getData().getInstallId();
                    next();
                }
            }

            @Override
            public void onFaileure(int code, Exception e) {
            }
        });
    }

    private void next() {
        if (!TextUtils.isEmpty(installId)) {
            SharedPreferences sp = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sp.edit();
            editor.putBoolean("", true);
            editor.apply();
            String s = getString();
            if (TextUtils.isEmpty(s)) {
                SharedPreferences shared = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
                SharedPreferences.Editor editor1 = shared.edit();
                editor1.putString("", installId);
                editor1.apply();
            }
        }
    }

    private String getString() {
        SharedPreferences sharedPreferences = mContext.getSharedPreferences("", Context.MODE_PRIVATE);
        return sharedPreferences.getString("", "");
    }

    private void livelyInfo(final String flag, final LinkedHashMap<String, String> linkedHashMap) {
        String jsonString = mapToJson(linkedHashMap);
        Map<String, String> sortMap = ParamTreeMap.getSortMap();
        sortMap.put("action", "");
        sortMap.put("installId", installId);
        sortMap.put("online_times", jsonString);
        sortMap.put("request_udid", startTime);
        sortMap.put("token", getToken(sortMap));
        HttpUtils.doHttpReqeust("POST", Link.formalLink, sortMap, AppInstallInfo.class, new HttpUtils.ObjectCallback<AppInstallInfo>() {
            @Override
            public void onSuccess(AppInstallInfo appInstallInfo) {
                linkedHashMap.clear();
            }

            @Override
            public void onFaileure(int code, Exception e) {
                switch (flag) {
                    case "thirtyfive":
                        LinkedHashMap<String, String> map = getMap(mContext, "", "");
                        if (!map.isEmpty()) {
                            linkedHashMap.putAll(map);
                        }
                        setMap(mContext, "", "", linkedHashMap);
                        break;
                    case "beforethirtyfive":
                        setMap(mContext, "", "", linkedHashMap);
                        break;
                }
            }
        });
    }

    private String packageName(Context context) {
        PackageManager manager = context.getPackageManager();
        String name = null;
        try {
            PackageInfo info = manager.getPackageInfo(context.getPackageName(), 0);
            name = info.versionName;
            if (TextUtils.isEmpty(name)) {
                return "";
            }
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }

        return name;
    }

    private String getContent(String dBoardContent) {
        String pbid = "";
        return pbid;
    }

    private String getToken(Map<String, String> sortMap) {
        String token = "";
        return token;
    }

    // 获取ApiKey
    public static String getMetaValue(Context context, String metaKey) {
        Bundle metaData = null;
        String apiKey = null;
        if (context == null || metaKey == null) {
            return null;
        }
        try {
            ApplicationInfo ai = context.getPackageManager()
                    .getApplicationInfo(context.getPackageName(),
                            PackageManager.GET_META_DATA);
            if (null != ai) {
                metaData = ai.metaData;
            }
            if (null != metaData) {
                apiKey = metaData.getString(metaKey);
            }
        } catch (Exception e) {

        }
        return apiKey;
    }

    public String getDBoardContent(Context context) {
        return null;
    }

    private void setMap(Context context, String spName, String key, LinkedHashMap<String, String> datas) {
        SharedPreferences sp = context.getSharedPreferences(spName, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sp.edit();
        JSONArray mJsonArray = new JSONArray();
        Iterator<Map.Entry<String, String>> iterator = datas.entrySet().iterator();
        JSONObject object = new JSONObject();
        while (iterator.hasNext()) {
            Map.Entry<String, String> entry = iterator.next();
            try {
                object.put(entry.getKey(), entry.getValue());
            } catch (Exception e) {

            }
        }
        mJsonArray.put(object);
        editor.putString(key, mJsonArray.toString());
        editor.commit();
    }

    private LinkedHashMap<String, String> getMap(Context context, String spName, String key) {
        SharedPreferences sp = context.getSharedPreferences(spName, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sp.edit();
        LinkedHashMap<String, String> datas = new LinkedHashMap<>();
        String result = sp.getString(key, "");
        try {
            JSONArray array = new JSONArray(result);
            for (int i = 0; i < array.length(); i++) {
                JSONObject itemObject = array.getJSONObject(i);
                JSONArray names = itemObject.names();
                if (names != null) {
                    for (int j = 0; j < names.length(); j++) {
                        String name = names.getString(j);
                        String value = itemObject.getString(name);
                        datas.put(name, value);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return datas;
    }

    private void clear(Context context, String spName) {
        SharedPreferences preferences = context.getSharedPreferences(spName, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = preferences.edit();
        editor.clear();
        editor.commit();
    }

    private String judge() {
        String s = "";
        String brand = android.os.Build.MANUFACTURER.toLowerCase();
        if (brand != null) {
            switch (brand) {
                case "meizu":
                    s = "魅族";
                    break;
                case "samsung":
                    s = "三星";
                    break;
                case "huawei":
                    s = "华为";
                    break;
                case "honor":
                    s = "荣耀";
                    break;
                case "xiaomi":
                    s = "小米";
                    break;
                case "oppo":
                    s = "OPPO";
                    break;
                case "vivo":
                    s = "vivo";
                    break;
                case "oneplus":
                    s = "一加";
                    break;
                case "nubia":
                    s = "努比亚";
                    break;
                case "lge":
                    s = "LG";
                    break;
                case "sony":
                    s = "索尼";
                    break;
                case "lenovo":
                    s = "联想";
                    break;
                case "360":
                    s = "360";
                    break;
                case "coolpad":
                    s = "酷派";
                    break;
                case "zte":
                    s = "中兴";
                    break;
                case "htc":
                    s = "HTC";
                    break;
                case "asus":
                    s = "华硕";
                    break;
            }
        }
        if (TextUtils.isEmpty(s)) {
            s = "其他";
        }
        return s;
    }

    public static Object[][] getMapKeyValue(Map map) {
        Object[][] object = null;
        if ((map != null) && (!map.isEmpty())) {
            int size = map.size();
            object = new Object[size][2];
            Iterator iterator = map.entrySet().iterator();
            for (int i = 0; i < size; i++) {
                Map.Entry entry = (Map.Entry) iterator.next();
                Object key = entry.getKey();
                Object value = entry.getValue();
                object[i][0] = key;
                object[i][1] = value;
            }
        }
        return object;
    }
}
