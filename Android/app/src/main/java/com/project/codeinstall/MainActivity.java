package com.project.codeinstall;

import androidx.appcompat.app.AppCompatActivity;

import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import com.project.codeinstallsdk.CodeInstall;
import com.project.codeinstallsdk.inter.ConfigCallBack;
import com.project.codeinstallsdk.model.Transfer;


public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        findViewById(R.id.get).setOnClickListener(this);
        findViewById(R.id.register).setOnClickListener(this);
        findViewById(R.id.registerWithCallback).setOnClickListener(this);

        //统计调用
        new CodeInstall(MainActivity.this, "statistics");

        //一键唤起相关
        Uri uri = getIntent().getData();
        if (uri != null) {
            String uriString = uri.toString();
            CodeInstall rouse = new CodeInstall(this, uriString, new ConfigCallBack() {

                @Override
                public void onResponse(Transfer transfer) {
                    //pbData里的信息即为自定义参数信息
                    Log.e("dgsdgsdg", "onResponseb: " + transfer.getChannelNo() + "::" + transfer.getPbData());
                }
            });
            rouse = null;
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        new CodeInstall(MainActivity.this, "Installation_with_parameters");
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.get:
                CodeInstall get_config = new CodeInstall(this, "Get_config", new ConfigCallBack() {
                    @Override
                    public void onResponse(Transfer transfer) {
                        //transfer.getChannelNo() + "::" + transfer.getPbData()
                    }
                });
                get_config = null;
                break;
            case R.id.register:
                //无回调的调用
                CodeInstall register = new CodeInstall(this, "register");
                register = null;
                break;
            case R.id.registerWithCallback:
                //有回调的调用
                CodeInstall registerWithCallback = new CodeInstall(this, "register", new ConfigCallBack() {

                    @Override
                    public void onResponse(Transfer transfer) {
                        //如果transfer.getMsg()为success,则代表统计注册量成功;
                        //如果transfer.getMsg()为error,则代表统计注册量失败;
                    }
                });
                registerWithCallback = null;
                break;
        }
    }
}