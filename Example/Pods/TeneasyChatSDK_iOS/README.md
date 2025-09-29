*起聊iOS SDK，集成文档*

**引用SDK:**
```
最新版：
pod 'TeneasyChatSDK_iOS', :git => 'https://github.com/QiSDK/QiChatSDK_iOS.git'

稳定版
pod 'TeneasyChatSDK_iOS', :git => 'https://github.com/QiSDK/QiChatSDK_iOS.git', :tag => '1.5.2'

如使用没有线路智能选择的版本，请指定到1.0.4
pod 'TeneasyChatSDK_iOS', :git => 'https://github.com/QiSDK/QiChatSDK_iOS.git', :tag => '1.0.4'
```

**侦测线路:**
```
  override func viewDidLoad() {
        super.viewDidLoad()
        //线路用逗号分开
        let lines = "https://abc.com,https://def.com"
        let lineLib = LineDetectLib(lines, delegate: self, tenantId: 123)//123是商户id
        lineLib.getLine()
    }

    func useTheLine(line: String){
        initSDK(baseUrl: line)
    }

    func lineError(error: Result){
        print(error.Message)
    }
```
    

**初始化SDK:** 
```
    var lib = ChatLib()

    func initSDK(baseUrl: String){
        let wssUrl = "wss://" + baseUrl + "/v1/gateway/h5?"
        //第一次cert必填，之后token必填
        lib = ChatLib(userId: 1125324, cert: "", token: "", baseUrl: wssUrl, sign: "9zgd9YUc")

        lib.callWebsocket()
        lib.delegate = self
    }
```

**实现代理方法:** 
```
在你的VC里面实现 teneasySDKDelegate 里面的方法

public protocol teneasySDKDelegate : AnyObject{
   //收到消息
    func receivedMsg(msg: CommonMessage)

    //消息回执
    func func msgReceipt(msg: CommonMessage, payloadId : UInt64 = 0, errMsg: String?)

    //系统消息，成功连接或断开连接都会触发此回调
    func systemMsg(result: Result)

    //连接状态
    func connected(c: Gateway_SCHi)

    //客服更换回调
    func workChanged(msg: Gateway_SCWorkerChanged)
}
```

**收到对方的消息:** 
```
    func receivedMsg(msg: CommonMessage) {
         if (msg.consultId != consultId){
          //忽略消息或给个提示
         }
         print(msg)

        switch msg.payload{
        case .content(msg.content):
            print("text")
        case .image(msg.image):
            print(msg.image)
        case .video(msg.video):
            print("video")
        case .audio(msg.audio):
            print("audio")
        default:
            print("ddd")
        }
    }
```


**断开链接：**
```    
deinit {
   lib.disConnect()
}
```

**发消息：**
```
发送文本消息：

let txtMsg = "你好！需要什么帮助？\n"
lib.sendMessage(msg: txtMsg, type: .msgText)
```

```
发送图片消息： 

路径拼接：baseUrl + 服务器返回的图片路径
lib.sendMessage(msg:"https://sssacc.wwc09.com/3/public/1/1695821236_29310.jpg", type: .Image)

或这样
lib.sendMessage(msg:"3/public/1/1695821236_29310.jpg", type: .Image) 
```

```
发送视频消息
 lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo)
 ```

**回复消息：**
```
例如使用一个视频回复msgId
  lib.sendMessage(msg: "https://www.youtube.com/watch?v=wbFHmblw9J8", type: .msgVideo, replyMsgId: msgID ?? 0)
```

**删除/撤回消息：**
```
lib.deleteMessage(msgId)

删除消息之后在msgReceipt会收到回执，判断msgId是否<0，通过payloadId从列表找到消息，然后进行UI上的删除
对方删除/撤回也是在msgReceipt里面收到
```

**获取正在发送消息的payloadId：**
```
var payloadId = lib.payloadId
```

**客服更换：**
```
回调函数：workChanged  
  消息包含这些字段
  workerID: Int32 = 0
  workerName: String = String()
  workerAvatar: String = String()
  target: Int64 = 0
  consultId: Int64 = 0
  reason: Gateway_WorkerChangedReason = .unknown

收到workChanged的回调后，做这样的判断：
if (msg.reason == GGateway.WorkerChangedReason.WorkerChangedReasonTransferWorker){
   //客服更换了
}
if (msg.reason == GGateway.WorkerChangedReason.WorkerChangedReasonWorkerDeleted){
  //被拉黑到xx客服了
}
```


**重发消息：**
```
lib.resendMSg(msg, payloadId);
```

```
能支持的消息枚举： 
 /// 文本
  case msgText // = 0

  /// 图片
  case msgImg // = 1

  /// voice
  case msgVoice // = 2

  /// 视频
  case msgVideo // = 3

  /// 地理位置
  case msgGeo // = 4

  /// 文件
  case msgFile // = 6
```

