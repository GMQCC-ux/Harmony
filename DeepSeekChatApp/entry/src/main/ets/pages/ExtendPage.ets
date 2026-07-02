/**
 * 拓展功能详情页
 * 针对翻译、摘要、代码生成等功能的专用交互界面
 * 使用组件：Image, Text, TextInput, Button, List
 */
import { router } from "@kit.ArkUI"
import { pasteboard } from "@kit.BasicServicesKit"
import { promptAction } from "@kit.ArkUI"
import { callDeepSeekApi } from "../common/DeepSeekApi"
import { DataManager } from "../common/DataManager"
import { ChatMessage, MessageRole, ExtendFeature } from "../model/ChatData"

// 路由参数接口
interface RouteParams {
  feature: ExtendFeature
  bgName: string
}

@Entry
@Component
struct ExtendPage {
  @State feature: ExtendFeature = {
    id: "",
    name: "",
    icon: "",
    description: "",
    prompt: ""
  }
  @State bgName: string = "bg_extend"
  private dataManager: DataManager = DataManager.getInstance()
  @State inputText: string = ""
  @State resultText: string = ""
  @State isLoading: boolean = false
  @State history: string[] = []

  aboutToAppear(): void {
    const params: RouteParams | undefined = router.getParams() as RouteParams | undefined
    if (params && params.feature) {
      this.feature = params.feature
      this.bgName = params.bgName || "bg_extend"
    }
  }

  copyText(text: string): void {
    const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    const sysPaste: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard()
    sysPaste.setData(pasteData)
    promptAction.showToast({ message: "已复制到剪贴板", duration: 1500 })
  }

  async handleSubmit(): Promise<void> {
    const text: string = this.inputText.trim()
    if (!text || this.isLoading) {
      return
    }

    this.isLoading = true
    this.resultText = ""

    const messages: ChatMessage[] = [
      new ChatMessage("sys", MessageRole.SYSTEM,
        "你是一个专业的" + this.feature.name + "助手。请高效准确地完成" + this.feature.name + "任务。"),
      new ChatMessage("user", MessageRole.USER,
        this.feature.prompt + "\n" + text)
    ]

    const apiKey: string = await this.dataManager.getApiKey()
    const reply: string = await callDeepSeekApi(apiKey, messages)
    this.resultText = reply
    this.isLoading = false

    this.history.unshift("[" + new Date().toLocaleTimeString() + "] " + text.slice(0, 30) + "...")
  }


  getBackground(): Resource {
    if (this.bgName === "bg_summary") { return $r("app.media.bg_summary") }
    if (this.bgName === "bg_code") { return $r("app.media.bg_code") }
    if (this.bgName === "bg_polish") { return $r("app.media.bg_polish") }
    if (this.bgName === "bg_qa") { return $r("app.media.bg_qa") }
    if (this.bgName === "bg_creative") { return $r("app.media.bg_creative") }
    return $r("app.media.bg_extend")
  }
  build(): void {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text("←")
            .fontSize(18)
            .fontColor("#333")
        }
        .width(36)
        .height(36)
        .backgroundColor("rgba(245,245,245,0.7)")
        .onClick(() => {
          router.back()
        })

        Text(this.feature.icon + " " + this.feature.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })

        Blank()
      }
      .width("100%")
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Text(this.feature.description)
        .fontSize(13)
        .fontColor("#666")
        .padding({ left: 16, right: 16, bottom: 8 })

      Column() {
        TextArea({ placeholder: "请输入" + this.feature.name + "的内容...", text: this.inputText })
          .width("100%")
          .height(120)
          .fontSize(15)
          .backgroundColor("rgba(248,249,255,0.7)")
          .borderRadius(12)
          .padding(14)
          .onChange((value: string) => {
            this.inputText = value
          })

        Button(this.isLoading ? "处理中..." : "开始" + this.feature.name)
          .width("100%")
          .height(46)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor("#4e6ef2")
          .borderRadius(12)
          .margin({ top: 12 })
          .enabled(!this.isLoading && this.inputText.trim().length > 0)
          .onClick(() => {
            this.handleSubmit()
          })
      }
      .padding({ left: 16, right: 16 })

      if (this.resultText || this.isLoading) {
        Column() {
          Text("处理结果")
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor("#333")
            .width("100%")
            .padding({ left: 16, top: 16, bottom: 8 })

         if (this.isLoading) {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
                .color("#4e6ef2")
              Text("AI正在处理...")
                .fontSize(14)
                .fontColor("#999")
                .margin({ left: 8 })
            }
            .width("100%")
            .padding({ left: 20 })
          } else {
            Column({ space: 6 }) {
              Scroll() {
                Text(this.resultText)
                  .fontSize(14)
                  .fontColor("#333")
                  .width("100%")
                  .padding(16)
              }
              .width("100%")
              .height(200)
              .backgroundColor("rgba(248,249,255,0.7)")
              .borderRadius(12)

              Button("\u{1F4CB} 复制结果")
                .fontSize(12)
                .fontColor("#4e6ef2")
                .backgroundColor("rgba(238,240,255,0.8)")
                .borderRadius(8)
                .height(32)
                .onClick(() => {
                  this.copyText(this.resultText)
                })
            }
            .margin({ left: 16, right: 16 })
            .clip(true)
          }
        }
        .width("100%")
      }

      if (this.history.length > 0) {
        Column() {
          Text("使用历史")
            .fontSize(13)
            .fontColor("#999")
            .padding({ left: 16, top: 12, bottom: 4 })

          List() {
            ForEach(this.history.slice(0, 10), (item: string) => {
              ListItem() {
                Text(item)
                  .fontSize(12)
                  .fontColor("#666")
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              }
            })
          }
          .layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: "#f0f0f0" })
        }
        .layoutWeight(1)
        .width("100%")
        .margin({ top: 8 })
      } else {
        Blank()
      }
    }
    .width("100%")
    .height("100%")
    .backgroundImage(this.getBackground())
    .backgroundImageSize(ImageSize.Cover)
  }
}
