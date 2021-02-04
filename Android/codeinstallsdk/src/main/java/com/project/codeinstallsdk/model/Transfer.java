package com.project.codeinstallsdk.model;

/*
 *Happy Programming
 */
public class Transfer {
    private String channelNo;
    private String pbData;
    private String msg;

    public Transfer(String msg) {
        this.msg = msg;
    }

    public Transfer(String channelNo, String pbData) {
        this.channelNo = channelNo;
        this.pbData = pbData;
    }

    public String getMsg() {
        return msg;
    }

    public void setMsg(String msg) {
        this.msg = msg;
    }

    public String getChannelNo() {
        return channelNo;
    }

    public void setChannelNo(String channelNo) {
        this.channelNo = channelNo;
    }

    public String getPbData() {
        return pbData;
    }

    public void setPbData(String pbData) {
        this.pbData = pbData;
    }
}
