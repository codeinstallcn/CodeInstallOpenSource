package com.project.codeinstallsdk.model;

/*
 *Happy Programming
 */
public class AppInstallInfo {

    /**
     * data : {"installId":"61f4fb2e438723021ff31a6b6e9a0aa6"}
     * code : 0
     * msg : 查询成功
     */

    private DataBean data;
    private int code;
    private String msg;

    public DataBean getData() {
        return data;
    }

    public void setData(DataBean data) {
        this.data = data;
    }

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMsg() {
        return msg;
    }

    public void setMsg(String msg) {
        this.msg = msg;
    }

    public static class DataBean {
        /**
         * installId : 61f4fb2e438723021ff31a6b6e9a0aa6
         */

        private String installId;

        public String getInstallId() {
            return installId;
        }

        public void setInstallId(String installId) {
            this.installId = installId;
        }
    }
}
