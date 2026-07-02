/**
 * 登录页面
 * 提供用户名密码登录、记住密码功能
 * 使用组件：Image, Text, TextInput, Button
 */
import { router } from "@kit.ArkUI"
import { DataManager } from "../common/DataManager"

@Entry
@Component
struct Index {
  @State username: string = ""
  @State password: string = ""
  @State rememberPwd: boolean = false
  @State isLoading: boolean = false
  @State errorMsg: string = ""
  private dataManager: DataManager = DataManager.getInstance()

  async aboutToAppear(): Promise<void> {
    const context: Context | undefined = this.getUIContext().getHostContext()
    if (context) {
      await this.dataManager.init(context)
    }
    const remembered = await this.dataManager.getRememberedLogin()
    if (remembered.remember) {
      this.username = remembered.username
      this.password = remembered.password
      this.rememberPwd = true
    }
    const loggedIn: boolean = await this.dataManager.isLoggedIn()
    if (loggedIn) {
      router.replaceUrl({ url: "pages/MainPage" })
    }
  }

  async handleLogin(): Promise<void> {
    if (!this.username.trim()) {
      this.errorMsg = "请输入用户名"
      return
    }
    if (!this.password.trim()) {
      this.errorMsg = "请输入密码"
      return
    }

    this.isLoading = true
    this.errorMsg = ""

    await new Promise<void>((resolve: Function) => {
      setTimeout(resolve, 800)
    })

    const success: boolean = await this.dataManager.login(this.username, this.password)
    await this.dataManager.saveRememberPassword(this.username, this.password, this.rememberPwd)

    this.isLoading = false

    if (success) {
      router.replaceUrl({ url: "pages/MainPage" })
    } else {
      this.errorMsg = "用户名或密码错误（默认：admin / 123456）"
    }
  }

  build(): void {
    Column() {
      Column() {
        Image($r("app.media.app_icon")).width(80).height(80).borderRadius(20).margin({ bottom: 16 })

        Text("DeepNote")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1a1a2e")

        Text("AI智能笔记与对话")
          .fontSize(14)
          .fontColor("#999")
          .margin({ top: 8 })
      }
      .width("100%")
      .padding({ top: 80, bottom: 40 })

      Column() {
        TextInput({ placeholder: "请输入用户名", text: this.username })
          .width("100%")
          .height(50)
          .fontSize(16)
          .backgroundColor("rgba(245,245,245,0.7)")
          .borderRadius(12)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.username = value
            this.errorMsg = ""
          })

        TextInput({ placeholder: "请输入密码", text: this.password })
          .width("100%")
          .height(50)
          .fontSize(16)
          .type(InputType.Password)
          .backgroundColor("rgba(245,245,245,0.7)")
          .borderRadius(12)
          .padding({ left: 16, right: 16 })
          .margin({ top: 16 })
          .onChange((value: string) => {
            this.password = value
            this.errorMsg = ""
          })

        Row() {
          Row() {
            Toggle({ type: ToggleType.Checkbox, isOn: this.rememberPwd })
              .width(20)
              .height(20)
              .onChange((isOn: boolean) => {
                this.rememberPwd = isOn
              })
            Text("记住密码")
              .fontSize(14)
              .fontColor("#666")
              .margin({ left: 6 })
          }

          Blank()

          if (this.errorMsg) {
            Text(this.errorMsg)
              .fontSize(13)
              .fontColor("#ff4d4f")
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width("100%")
        .margin({ top: 16 })

        Button(this.isLoading ? "登录中..." : "登 录")
          .width("100%")
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor("#4e6ef2")
          .borderRadius(12)
          .margin({ top: 32 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin()
          })
      }
      .width("100%")
      .padding({ left: 32, right: 32 })

      Row() {
        Button("没有账户？注册")
          .fontSize(13)
          .fontColor("#4e6ef2")
          .backgroundColor("transparent")
          .onClick(() => {
            router.pushUrl({ url: "pages/RegisterPage" })
          })
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .margin({ top: 12 })

      Blank()

      Text("默认账号：admin / 123456")
        .fontSize(12)
        .fontColor("#bbb")
        .margin({ bottom: 24 })
    }
    .width("100%")
    .height("100%")
    .backgroundImage($r("app.media.bg_index"))
    .backgroundImageSize(ImageSize.Cover)
  }
}
