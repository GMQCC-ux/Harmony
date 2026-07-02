/**
 * 主页面
 */
import { router, promptAction } from "@kit.ArkUI"
import { pasteboard } from "@kit.BasicServicesKit"
import { DataManager } from "../common/DataManager"
import { callDeepSeekApi } from "../common/DeepSeekApi"
import { ChatMessage, MessageRole, Conversation, ExtendFeature, EXTEND_FEATURES } from "../model/ChatData"

let convIdCounter: number = Date.now()
function generateId(): string {
  return "msg_" + (convIdCounter++) + "_" + Math.random().toString(36).slice(2, 8)
}

// ============ AI对话 ============
@Component
struct ChatTab {
  @State inputText: string = ""
  @State messages: ChatMessage[] = []
  @State isLoading: boolean = false
  @State selectMode: boolean = false
  @State selectedIds: string[] = []
  @Link conversations: Conversation[]
  @State currentConvId: string = ""
  private dataManager: DataManager = DataManager.getInstance()
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void { this.startNewChat() }

  copyText(text: string): void {
    const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    pasteboard.getSystemPasteboard().setData(pasteData)
    promptAction.showToast({ message: "已复制到剪贴板", duration: 1500 })
  }

  toggleSelectMode(): void {
    this.selectMode = !this.selectMode
    if (!this.selectMode) { this.selectedIds = [] }
  }

  toggleMessageSelect(msgId: string): void {
    const idx: number = this.selectedIds.indexOf(msgId)
    if (idx >= 0) { this.selectedIds.splice(idx, 1) }
    else { this.selectedIds.push(msgId) }
  }

  isSelected(msgId: string): boolean { return this.selectedIds.indexOf(msgId) >= 0 }

  generateNote(): void {
    const selectedMsgs: ChatMessage[] = this.messages.filter((m: ChatMessage) => { return this.selectedIds.indexOf(m.id) >= 0 })
    const content: string = selectedMsgs.map((m: ChatMessage) => { return "[" + (m.role === MessageRole.USER ? "用户" : "AI") + "] " + m.content }).join("\n\n")
    this.selectMode = false
    this.selectedIds = []
    router.pushUrl({ url: "pages/NoteEditor", params: { selectedContent: content } })
  }

  startNewChat(): void {
    this.currentConvId = generateId()
    this.messages = []
    this.messages.push(new ChatMessage(generateId(), MessageRole.ASSISTANT, "你好！我是DeepNote，基于DeepSeek大语言模型。有什么可以帮助你的吗？"))
  }

  async sendMessage(): Promise<void> {
    const text: string = this.inputText.trim()
    if (!text || this.isLoading) { return }
    this.messages.push(new ChatMessage(generateId(), MessageRole.USER, text))
    this.inputText = ""
    this.isLoading = true
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 100)
    const apiKey: string = await this.dataManager.getApiKey()
    const reply: string = await callDeepSeekApi(apiKey, this.messages)
    this.messages.push(new ChatMessage(generateId(), MessageRole.ASSISTANT, reply))
    this.isLoading = false
    this.saveCurrentConv()
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 100)
  }

  saveCurrentConv(): void {
    let conv: Conversation | undefined = this.conversations.find((c: Conversation) => c.id === this.currentConvId)
    if (!conv) {
      conv = new Conversation(this.currentConvId, this.messages.length > 1 ? (this.messages[this.messages.length - 2]?.content.slice(0, 30) || "新对话") : "新对话")
      this.conversations.unshift(conv)
    }
    conv.messages = [...this.messages]
    conv.updateTime = Date.now()
    if (conv.messages.length > 1 && conv.title === "新对话") { conv.title = this.messages[1]?.content.slice(0, 30) || "新对话" }
  }

  build(): void {
    Stack() {
      Image($r("app.media.bg_chat")).width("100%").height("100%").objectFit(ImageFit.Cover)
      Column() {
        Row() {
          Text("AI 对话").fontSize(20).fontWeight(FontWeight.Bold).fontColor("#1a1a2e")
          Blank()
          Button(this.selectMode ? "取消" : "选择").fontSize(14).fontColor("#4e6ef2").backgroundColor("rgba(238,240,255,0.8)").borderRadius(8).height(36).margin({ right: 8 }).onClick(() => { this.toggleSelectMode() })
          Button("新对话").fontSize(14).fontColor("#4e6ef2").backgroundColor("rgba(238,240,255,0.8)").borderRadius(8).height(36).onClick(() => { this.startNewChat() })
        }.width("100%").padding({ left: 20, right: 20, top: 12, bottom: 12 })

        List({ scroller: this.scroller }) {
          ForEach(this.messages, (msg: ChatMessage) => {
            ListItem() {
              Row() {
                if (this.selectMode) {
                  Checkbox({ name: msg.id, group: "msgGroup" }).select(this.isSelected(msg.id)).onChange((checked: boolean) => { this.toggleMessageSelect(msg.id) }).margin({ right: 8 })
                }
                if (msg.role === MessageRole.USER) { Blank() }
                Column({ space: 4 }) {
                  Column() {
                    Text(msg.content).fontSize(15).fontColor(msg.role === MessageRole.USER ? "#fff" : "#333").padding(12).borderRadius(16).backgroundColor(msg.role === MessageRole.USER ? "#4e6ef2" : "rgba(240,240,240,0.85)").constraintSize({ maxWidth: "75%" }).textAlign(msg.role === MessageRole.USER ? TextAlign.End : TextAlign.Start)
                  }
                  if (msg.role === MessageRole.ASSISTANT || msg.role === MessageRole.USER) {
                    Button("📋 复制").fontSize(11).fontColor("#999").backgroundColor("transparent").height(24).padding({ left: 6, right: 6 }).onClick(() => { this.copyText(msg.content) })
                  }
                }
                if (msg.role === MessageRole.ASSISTANT) { Blank() }
              }.width("100%").padding({ left: 16, right: 16, top: 6, bottom: 6 })
            }
          })
          if (this.isLoading) {
            ListItem() {
              Row() {
                LoadingProgress().width(24).height(24).color("#4e6ef2")
                Text("AI正在思考...").fontSize(13).fontColor("#999").margin({ left: 8 })
              }.padding({ left: 16, top: 8, bottom: 8 })
            }
          }
        }.layoutWeight(1).width("100%").backgroundColor("rgba(250,250,250,0.7)").divider({ strokeWidth: 0 })

        if (this.selectMode && this.selectedIds.length > 0) {
          Row() {
            Text("已选 " + this.selectedIds.length + " 条消息").fontSize(14).fontColor("#333")
            Blank()
            Button("✨ 生成总结笔记").fontSize(14).fontColor(Color.White).backgroundColor("#4e6ef2").borderRadius(20).height(40).padding({ left: 20, right: 20 }).onClick(() => { this.generateNote() })
          }.width("100%").padding({ left: 16, right: 16, top: 8, bottom: 4 }).backgroundColor("rgba(238,240,255,0.8)")
        }

        Row() {
          TextInput({ placeholder: "输入消息...", text: this.inputText }).layoutWeight(1).height(44).fontSize(15).backgroundColor("rgba(245,245,245,0.7)").borderRadius(22).padding({ left: 16, right: 16 }).onChange((value: string) => { this.inputText = value }).onSubmit(() => { this.sendMessage() })
          Button("发送").fontSize(14).fontColor(Color.White).backgroundColor("#4e6ef2").borderRadius(22).height(44).width(64).margin({ left: 10 }).enabled(!this.isLoading && this.inputText.trim().length > 0).onClick(() => { this.sendMessage() })
        }.width("100%").padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor("rgba(255,255,255,0.85)")
      }.width("100%").height("100%")
    }
  }
}

// ============ 历史记录 ============
@Component
struct HistoryTab {
  @Link conversations: Conversation[]

  formatTime(timestamp: number): string {
    const d: Date = new Date(timestamp)
    return (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getDate().toString().padStart(2, "0") + " " + d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
  }

  deleteConversation(convId: string): void {
    const index: number = this.conversations.findIndex((c: Conversation) => c.id === convId)
    if (index >= 0) { this.conversations.splice(index, 1) }
  }

  build(): void {
    Stack() {
      Image($r("app.media.bg_history")).width("100%").height("100%").objectFit(ImageFit.Cover)
      Column() {
        Text("历史记录").fontSize(20).fontWeight(FontWeight.Bold).fontColor("#1a1a2e").width("100%").padding({ left: 20, top: 16, bottom: 16 })
        if (this.conversations.length === 0) {
          Column() {
            Text("📭").fontSize(48).margin({ bottom: 12 })
            Text("暂无聊天记录").fontSize(15).fontColor("#999")
            Text("开始一段新对话吧").fontSize(13).fontColor("#bbb").margin({ top: 4 })
          }.width("100%").layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.conversations, (conv: Conversation) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(conv.title || "新对话").fontSize(15).fontColor("#333").maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(conv.messages.length + " 条消息 · " + this.formatTime(conv.updateTime)).fontSize(12).fontColor("#999").margin({ top: 4 })
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Button({ type: ButtonType.Circle }) { Text("✕").fontSize(14).fontColor("#ff4d4f") }.width(32).height(32).backgroundColor("rgba(255,240,240,0.8)").onClick(() => { this.deleteConversation(conv.id) })
                }.width("100%").padding({ left: 20, right: 20, top: 14, bottom: 14 })
              }.onClick(() => { router.pushUrl({ url: "pages/ConversationDetail", params: { convId: conv.id } }) })
            })
          }.layoutWeight(1).divider({ strokeWidth: 0.5, color: "#eee" })
        }
      }.width("100%").height("100%")
    }
  }
}

// ============ 拓展功能 ============
@Component
struct ExtendTab {
  @State features: ExtendFeature[] = EXTEND_FEATURES

  getBgName(featureId: string): string {
    if (featureId === "translate") { return "bg_extend" }
    return "bg_" + featureId
  }

  build(): void {
    Stack() {
      Image($r("app.media.bg_extendtab")).width("100%").height("100%").objectFit(ImageFit.Cover)
      Column() {
        Text("拓展功能").fontSize(20).fontWeight(FontWeight.Bold).fontColor("#1a1a2e").width("100%").padding({ left: 20, top: 16, bottom: 8 })
        Swiper() {
          ForEach(["欢迎使用DeepNote", "智能翻译 · 多语言支持", "代码生成 · 高效编程", "知识问答 · 无所不知"], (item: string) => {
            Text(item).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White).width("100%").height("100%").textAlign(TextAlign.Center).backgroundColor("#4e6ef2").borderRadius(14)
          })
        }.width("100%").height(140).padding({ left: 16, right: 16 }).autoPlay(true).interval(3000).indicator(Indicator.dot().color("#ccc").selectedColor("#4e6ef2")).margin({ bottom: 12 })
        Grid() {
          ForEach(this.features, (feature: ExtendFeature) => {
            GridItem() {
              Column() {
                Text(feature.icon).fontSize(36).margin({ bottom: 8 })
                Text(feature.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor("#333").margin({ bottom: 2 })
                Text(feature.description).fontSize(11).fontColor("#999").maxLines(1)
              }
              .width("100%")
              .height("100%")
              .justifyContent(FlexAlign.Center)
              .borderRadius(12)
              .backgroundColor("rgba(248,249,255,0.7)")
              .onClick(() => {
                router.pushUrl({ url: "pages/ExtendPage", params: { feature: feature, bgName: this.getBgName(feature.id) } })
              })
            }
          })
        }.columnsTemplate("1fr 1fr 1fr").rowsTemplate("1fr 1fr").columnsGap(12).rowsGap(12).width("100%").height(260).padding({ left: 16, right: 16 })
      }.width("100%").height("100%")
    }
  }
}

// ============ 主入口 ============
@Entry
@Component
struct MainPage {
  @State currentTabIndex: number = 0
  @State conversations: Conversation[] = []
  private dataManager: DataManager = DataManager.getInstance()

  async aboutToAppear(): Promise<void> { this.conversations = await this.dataManager.loadConversations() }
  async onPageHide(): Promise<void> { await this.dataManager.saveConversations(this.conversations) }
  async handleLogout(): Promise<void> { await this.dataManager.saveConversations(this.conversations); await this.dataManager.logout(); router.replaceUrl({ url: "pages/Index" }) }

  build(): void {
    Column() {
      Tabs({ index: this.currentTabIndex }) {
        TabContent() { ChatTab({ conversations: $conversations }) }.tabBar("AI对话").backgroundColor(Color.Transparent)
        TabContent() { HistoryTab({ conversations: $conversations }) }.tabBar("历史记录").backgroundColor(Color.Transparent)
        TabContent() { ExtendTab() }.tabBar("拓展功能").backgroundColor(Color.Transparent)
      }
      .backgroundColor(Color.Transparent).barMode(BarMode.Fixed).barWidth("100%").barHeight(48).layoutWeight(1).onChange((index: number) => { this.currentTabIndex = index }).scrollable(false)

      Row() {
        Button("📝 笔记").fontSize(12).fontColor("#4e6ef2").backgroundColor("rgba(238,240,255,0.8)").borderRadius(8).height(34).layoutWeight(1).margin({ right: 6 }).onClick(() => { router.pushUrl({ url: "pages/NotesList" }) })
        Button("🔑 密钥").fontSize(12).fontColor("#e67e22").backgroundColor("rgba(255,245,230,0.8)").borderRadius(8).height(34).layoutWeight(1).margin({ right: 6 }).onClick(() => { router.pushUrl({ url: "pages/ApiSetupPage" }) })
        Button("退出登录").fontSize(12).fontColor("#ff4d4f").backgroundColor("rgba(255,240,240,0.8)").borderRadius(8).height(34).layoutWeight(1).onClick(() => { this.handleLogout() })
      }.width("100%").padding({ left: 20, right: 20, top: 6, bottom: 8 }).backgroundColor("rgba(250,250,250,0.7)")
    }.width("100%").height("100%").backgroundImage($r("app.media.bg_main")).backgroundImageSize(ImageSize.Cover)
  }
}
