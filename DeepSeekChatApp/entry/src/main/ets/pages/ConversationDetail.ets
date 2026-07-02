import { router } from "@kit.ArkUI"
import { ChatMessage, MessageRole, Conversation } from "../model/ChatData"
import { DataManager } from "../common/DataManager"

interface DetailParams {
  convId: string
}

@Entry
@Component
struct ConversationDetail {
  @State messages: ChatMessage[] = []
  @State title: string = ""
  private dataManager: DataManager = DataManager.getInstance()

  async aboutToAppear(): Promise<void> {
    const params: DetailParams | undefined = router.getParams() as DetailParams | undefined
    if (params) {
      const conversations: Conversation[] = await this.dataManager.loadConversations()
      const conv: Conversation | undefined = conversations.find((c: Conversation) => c.id === params.convId)
      if (conv) {
        this.title = conv.title || "对话详情"
        this.messages = [...conv.messages]
      }
    }
  }

  build(): void {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text("←").fontSize(18).fontColor("#333")
        }.width(36).height(36).backgroundColor("rgba(245,245,245,0.7)").onClick(() => router.back())

        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold)
          .margin({ left: 12 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
      }.width("100%").padding({ left: 16, right: 16, top: 12, bottom: 12 })

      List() {
        ForEach(this.messages, (msg: ChatMessage) => {
          ListItem() {
            Row() {
              if (msg.role === MessageRole.USER) { Blank() }
              Column() {
                Text(msg.content).fontSize(15)
                  .fontColor(msg.role === MessageRole.USER ? "#fff" : "#333")
                  .padding(12).borderRadius(16)
                  .backgroundColor(msg.role === MessageRole.USER ? "#4e6ef2" : "#f0f0f0")
                  .constraintSize({ maxWidth: "75%" })
                  .textAlign(msg.role === MessageRole.USER ? TextAlign.End : TextAlign.Start)
              }
              if (msg.role === MessageRole.ASSISTANT) { Blank() }
            }.width("100%").padding({ left: 16, right: 16, top: 6, bottom: 6 })
          }
        })
      }.layoutWeight(1).width("100%").backgroundColor("rgba(250,250,250,0.7)").divider({ strokeWidth: 0 })
    }.width("100%").height("100%").backgroundImage($r("app.media.bg_detail")).backgroundImageSize(ImageSize.Cover)
  }
}