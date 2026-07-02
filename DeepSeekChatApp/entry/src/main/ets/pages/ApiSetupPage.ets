/**
 * API密钥配置页
 */
import { router, promptAction } from "@kit.ArkUI"
import { DataManager } from "../common/DataManager"

@Entry
@Component
struct ApiSetupPage {
  @State apiKey: string = ""
  @State isLoading: boolean = false
  private dataManager: DataManager = DataManager.getInstance()

  async aboutToAppear(): Promise<void> {
    const existingKey: string = await this.dataManager.getApiKey()
    if (existingKey) {
      this.apiKey = existingKey
    }
  }

  async handleSave(): Promise<void> {
    const key: string = this.apiKey.trim()
    if (!key) {
      promptAction.showToast({ message: "请输入API密钥", duration: 1500 })
      return
    }
    this.isLoading = true
    await this.dataManager.saveApiKey(key)
    this.isLoading = false
    promptAction.showToast({ message: "保存成功", duration: 1500 })
    setTimeout(() => { router.replaceUrl({ url: "pages/MainPage" }) }, 800)
  }

  handleSkip(): void {
    router.replaceUrl({ url: "pages/MainPage" })
  }

  build(): void {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text("←").fontSize(18).fontColor("#333")
        }.width(36).height(36).backgroundColor("rgba(245,245,245,0.7)")
        .onClick(() => { router.back() })
        Blank()
      }.width("100%").padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Column() {
        Text("🔑").fontSize(48).margin({ bottom: 12 })
        Text("配置API密钥").fontSize(24).fontWeight(FontWeight.Bold).fontColor("#1a1a2e")
        Text("请输入你的DeepSeek API Key").fontSize(13).fontColor("#999").margin({ top: 8 })
      }.width("100%").padding({ top: 40, bottom: 30 })

      Column() {
        TextArea({ placeholder: "sk-xxxxxxxxxxxxxxxxxxxxxxxx", text: this.apiKey })
          .width("100%").height(100).fontSize(14)
          .backgroundColor("rgba(245,245,245,0.85)").borderRadius(12).padding(14)
          .onChange((v: string) => { this.apiKey = v })

        Text("API Key 可在 DeepSeek 官网免费获取，密钥仅存储在本地").fontSize(11).fontColor("#bbb").margin({ top: 8 })

        Row() {
          Button(this.isLoading ? "保存中..." : "保存")
            .layoutWeight(1).height(44).fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor(Color.White).backgroundColor("#4e6ef2").borderRadius(12)
            .margin({ right: 8 }).enabled(!this.isLoading)
            .onClick(() => { this.handleSave() })
          Button("跳过")
            .layoutWeight(1).height(44).fontSize(15).fontColor("#666")
            .backgroundColor("rgba(240,240,240,0.85)").borderRadius(12)
            .onClick(() => { this.handleSkip() })
        }.margin({ top: 20 })
      }.width("100%").padding({ left: 32, right: 32 })

      Blank()
    }.width("100%").height("100%")
    .backgroundImage($r("app.media.bg_apisetup")).backgroundImageSize(ImageSize.Cover)
  }
}
