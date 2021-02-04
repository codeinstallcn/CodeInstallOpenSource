package com.project.codeinstallsdk.model;

/*
 *Happy Programming
 */
public class Rouse {

    /**
     * channelNo :
     * data : {"channelNo":"bb"}
     */

    private String channelNo;
    private DataBean data;

    public String getChannelNo() {
        return channelNo;
    }

    public void setChannelNo(String channelNo) {
        this.channelNo = channelNo;
    }

    public DataBean getData() {
        return data;
    }

    public void setData(DataBean data) {
        this.data = data;
    }

    public static class DataBean {
        /**
         * channelNo : bb
         */

        private String channelNo;

        public String getChannelNo() {
            return channelNo;
        }

        public void setChannelNo(String channelNo) {
            this.channelNo = channelNo;
        }
    }
}
