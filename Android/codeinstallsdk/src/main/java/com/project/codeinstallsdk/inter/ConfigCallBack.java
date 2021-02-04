package com.project.codeinstallsdk.inter;

import com.project.codeinstallsdk.model.ConfigInfo;
import com.project.codeinstallsdk.model.Rouse;
import com.project.codeinstallsdk.model.Transfer;

import java.util.Map;

/*
 *Happy Programming
 */
public interface ConfigCallBack {
    void onResponse(Transfer configinfo);
    //void RouseCallBack(Transfer rouse);
}
