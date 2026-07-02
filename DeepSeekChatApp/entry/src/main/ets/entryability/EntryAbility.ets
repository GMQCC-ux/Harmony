/**
 * 应用入口Ability
 * 负责应用的生命周期管理和窗口创建
 */
import { UIAbility, Want, AbilityConstant } from "@kit.AbilityKit"
import { BusinessError } from "@kit.BasicServicesKit"
import { window } from "@kit.ArkUI"

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info("DeepSeekChatApp EntryAbility onCreate")
  }

  onDestroy(): void {
    console.info("DeepSeekChatApp EntryAbility onDestroy")
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info("DeepSeekChatApp EntryAbility onWindowStageCreate")

    windowStage.loadContent("pages/Index", (err: BusinessError) => {
      if (err.code) {
        console.error("Failed to load content: " + JSON.stringify(err))
        return
      }
      console.info("WindowStage loadContent succeeded")
    })
  }

  onWindowStageDestroy(): void {
    console.info("DeepSeekChatApp EntryAbility onWindowStageDestroy")
  }

  onForeground(): void {
    console.info("DeepSeekChatApp EntryAbility onForeground")
  }

  onBackground(): void {
    console.info("DeepSeekChatApp EntryAbility onBackground")
  }
}
