import Foundation

public enum OutboundMessageContent {
    case text(String)
    case image(uri: String)
    case file(uri: String, size: Int32, name: String)
    case audio(uri: String)
    case video(uri: String, thumbnailURI: String, hlsURI: String)
}

struct OutboundMessage {
    var consultId: Int64
    var replyMessageId: Int64
    var workerId: Int32
    var withAutoReply: CommonWithAutoReply?
    var content: OutboundMessageContent

    init(consultId: Int64,
         replyMessageId: Int64 = 0,
         workerId: Int32,
         withAutoReply: CommonWithAutoReply? = nil,
         content: OutboundMessageContent) {
        self.consultId = consultId
        self.replyMessageId = replyMessageId
        self.workerId = workerId
        self.withAutoReply = withAutoReply
        self.content = content
    }
}

enum MessageBuilder {
    static func makeCommonMessage(from outbound: OutboundMessage, chatId: Int64) -> CommonMessage {
        var message = CommonMessage()
        message.consultID = outbound.consultId
        message.replyMsgID = outbound.replyMessageId
        message.chatID = chatId
        message.worker = outbound.workerId
        message.sender = 0
        message.msgTime.seconds = Int64(Date().timeIntervalSince1970)

        switch outbound.content {
        case .text(let text):
            var payload = CommonMessageContent()
            payload.data = text
            message.msgFmt = .msgText
            message.payload = .content(payload)
            message.content = payload
        case .image(let uri):
            var payload = CommonMessageImage()
            payload.uri = uri
            message.msgFmt = .msgImg
            message.payload = .image(payload)
            message.image = payload
        case .file(let uri, let size, let name):
            var payload = CommonMessageFile()
            payload.uri = uri
            payload.size = size
            payload.fileName = name
            message.msgFmt = .msgFile
            message.payload = .file(payload)
            message.file = payload
        case .audio(let uri):
            var payload = CommonMessageAudio()
            payload.uri = uri
            message.msgFmt = .msgVoice
            message.payload = .audio(payload)
            message.audio = payload
        case .video(let uri, let thumbnail, let hls):
            var payload = CommonMessageVideo()
            payload.uri = uri
            payload.thumbnailUri = thumbnail
            payload.hlsUri = hls
            message.msgFmt = .msgVideo
            message.payload = .video(payload)
            message.video = payload
        }

        if let withAutoReply = outbound.withAutoReply {
            message.withAutoReplies = [withAutoReply]
        }

        return message
    }
}
