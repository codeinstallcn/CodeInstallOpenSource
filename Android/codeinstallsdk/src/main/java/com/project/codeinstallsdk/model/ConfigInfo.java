package com.project.codeinstallsdk.model;

/*
 *Happy Programming
 */
public class ConfigInfo {
    /**
     * code : 0
     * msg : 执行成功
     * data : {"installId":"2f6f6efb773faf41d57933afc67058d7aabe0586","channelNo":"","pbData":"{\"channelNo\":\"bb\"}"}
     */

    private int code;
    private String msg;
    private DataBean data;

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

    public DataBean getData() {
        return data;
    }

    public void setData(DataBean data) {
        this.data = data;
    }

    public static class DataBean {
        /**
         * installId : 2f6f6efb773faf41d57933afc67058d7aabe0586
         * channelNo :
         * pbData : {"channelNo":"bb"}
         */

        private String installId;
        private String channelNo;
        private String pbData;

        public String getInstallId() {
            return installId;
        }

        public void setInstallId(String installId) {
            this.installId = installId;
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

}
