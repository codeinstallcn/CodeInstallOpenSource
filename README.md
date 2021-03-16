[CodeInstall](https://www.codeinstall.com)
==============
CodeInstall是一款协助APP高效推广的产品，它可以自动精准追踪(iOS、Android)APP安装来源、安装渠道，产出近乎实时的统计数据，为运营决策提供全面、准确、可靠的依据。

#### 实现原理如下图：

![Benchmark result](https://res.codeinstall.vip/codeinstall_activity/static/assets/docs/productInfo/codeInstall_principle.svg)


产品功能：
==============
### 一、携带参数安装，打通浏览器和APP的桥梁
- 开发者可以在下载、分享的URL上自定义需要传到APP的参数，如邀请码、房间号、聊天室号、活动ID等。
- 使用者在终端点开对应的URL，CodeInstall的WebSDK自动获取URL上的参数，并发送到CodeInstall服务器，CodeInstall服务器自动匹配用户和参数并进行存储，为还原做准备。
- 使用者打开APP，CodeInstall的（iOS、Andriod）SDK精准还原对应的参数，开发者根据SDK返回的参数实现自己的业务逻辑。
- 通过以上功能可以简单实现：无需填写邀请码进行注册，自动绑定推广关系；无需填写对战房间号，打开分享URL自动进入对战房间；无需寻找活动，打开APP自动进入到活动页面，等等。

### 二、一键拉起、快速安装
- 支持移动端主流浏览器一键带参拉起APP。
- 使用cdn，全球加速，让APP快速安装。

### 三、渠道统计
- CodeInstall提供h5渠道下载链接生成功能，无需用户重新打包，支持用户自定义渠道参数，支持系统自动生成渠道参数，支持批量生成h5渠道下载链接。
- 终端用户扫码或在浏览器上打开h5渠道下载链接，下载页面自带CodeInstall的WebSDK，自动收集渠道信息和渠道指纹，发送到CodeInstall服务器存储。
- 用户下载完应用并打开时APP中CodeInstall的SDK将渠道及渠道指纹发送到服务器端验证，验证通过后才会将该用户划给该渠道。
CodeInstall提供近乎实时的渠道报表数据，供运营人员分析决策。



文档
==============
你可以在 [CodeInstall](https://www.codeinstall.com/docs/productInfo.html) 官方网站查看在线 API 文档


许可证
==============
CodeInstall 使用 MIT 许可证，详情见 LICENSE 文件。


