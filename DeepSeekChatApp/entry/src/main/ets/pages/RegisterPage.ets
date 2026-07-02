import { router, promptAction } from "@kit.ArkUI"
import { DataManager } from "../common/DataManager"

@Entry
@Component
struct RegisterPage {
  @State username: string = ""
  @State password: string = ""
  @State confirmPwd: string = ""
  @State isLoading: boolean = false
  @State errorMsg: string = ""
  private dataManager: DataManager = DataManager.getInstance()

  async handleRegister(): Promise<void> {
    if (!this.username.trim()) { this.errorMsg = "请输入用户名"; return }
    if (this.username.trim().length < 3) { this.errorMsg = "用户名至少3个字符"; return }
    if (!this.password.trim()) { this.errorMsg = "请输入密码"; return }
    if (this.password.trim().length < 4) { this.errorMsg = "密码至少4个字符"; return }
    if (this.password !== this.confirmPwd) { this.errorMsg = "两次密码不一致"; return }

    this.isLoading = true
    this.errorMsg = ""
    await new Promise<void>((r: Function) => setTimeout(r, 500))
    const success: boolean = await this.dataManager.register(this.username.trim(), this.password)
    this.isLoading = false

    if (success) {
      promptAction.showToast({ message: "注册成功，请登录", duration: 1500 })
      setTimeout(() => router.back(), 800)
    } else {
      this.errorMsg = "用户名已存在"
    }
  }

  build(): void {
    Column() {
      Column() {
        Image($r("app.media.app_icon")).width(80).height(80).borderRadius(20).margin({ bottom: 16 })
        Text("DeepNote").fontSize(28).fontWeight(FontWeight.Bold).fontColor("#1a1a2e")
        Text("创建新账户").fontSize(14).fontColor("#999").margin({ top: 8 })
      }.width("100%").padding({ top: 60, bottom: 30 })

      Column() {
        TextInput({ placeholder: "请输入用户名\uFF08\u81F3\u5C113\u4F4D\uFF09", text: this.username }).width("100%").height(50).fontSize(16)
          .backgroundColor("rgba(245,245,245,0.85)").borderRadius(12).padding({ left: 16, right: 16 })
          .onChange((v: string) => { this.username = v; this.errorMsg = "" })

        TextInput({ placeholder: "请输入密码（至少4位）", text: this.password }).width("100%").height(50).fontSize(16)
          .type(InputType.Password).backgroundColor("rgba(245,245,245,0.85)").borderRadius(12)
          .padding({ left: 16, right: 16 }).margin({ top: 16 })
          .onChange((v: string) => { this.password = v; this.errorMsg = "" })

        TextInput({ placeholder: "请确认密码", text: this.confirmPwd }).width("100%").height(50).fontSize(16)
          .type(InputType.Password).backgroundColor("rgba(245,245,245,0.85)").borderRadius(12)
          .padding({ left: 16, right: 16 }).margin({ top: 16 })
          .onChange((v: string) => { this.confirmPwd = v; this.errorMsg = "" })

        if (this.errorMsg) { Text(this.errorMsg).fontSize(13).fontColor("#ff4d4f").margin({ top: 12 }) }

        Button(this.isLoading ? "注册中..." : "注 册").width("100%").height(50).fontSize(18)
          .fontWeight(FontWeight.Bold).fontColor(Color.White).backgroundColor("#4e6ef2")
          .borderRadius(12).margin({ top: 32 }).enabled(!this.isLoading)
          .onClick(() => { this.handleRegister() })

        Button("已有账户？返回登录").fontSize(13).fontColor("#4e6ef2")
          .backgroundColor("transparent").margin({ top: 16 })
          .onClick(() => { router.back() })
      }.width("100%").padding({ left: 32, right: 32 })

      Blank()
    }.width("100%").height("100%")
    .backgroundImage($r("app.media.bg_register")).backgroundImageSize(ImageSize.Cover)
  }
}