import { router, promptAction } from "@kit.ArkUI"
import { callDeepSeekApi } from "../common/DeepSeekApi"
import { stripMarkdown } from "../common/TextUtil"
import { ChatMessage, MessageRole, Note } from "../model/ChatData"
import { DataManager } from "../common/DataManager"

interface NoteParams {
  selectedContent: string
  noteId: string
  noteContent: string
  noteTitle: string
}

@Entry
@Component
struct NoteEditor {
  @State sourceText: string = ""
  @State summaryText: string = ""
  @State isLoading: boolean = true
  @State isSaving: boolean = false
  @State titleText: string = ""
  private editNoteId: string = ""
  private isEditMode: boolean = false
  private dataManager: DataManager = DataManager.getInstance()

  async aboutToAppear(): Promise<void> {
    const params: NoteParams | undefined = router.getParams() as NoteParams | undefined
    if (!params) { return }

    if (params.noteId) {
      this.editNoteId = params.noteId
      this.isEditMode = true
      this.sourceText = ""
      this.summaryText = params.noteContent || ""
      this.titleText = params.noteTitle || ""
      this.isLoading = false
    } else if (params.selectedContent) {
      this.sourceText = params.selectedContent
      await this.generateSummary()
    }
  }

  async generateSummary(): Promise<void> {
    this.isLoading = true
    const messages: ChatMessage[] = [
      new ChatMessage("sys", MessageRole.SYSTEM,
        "你是一个专业的内容总结助手。请提取以下对话中的关键信息，用结构化方式输出总结笔记。" +
        "要求：1.提炼核心观点和结论 2.按要点分条列出 3.保留重要的数据和事实 4.语言简洁精炼。" +
        "注意：请使用纯文本输出，不要使用Markdown格式标记（如**、#、-、*等符号）。"),
      new ChatMessage("user", MessageRole.USER, "请总结以下对话内容的关键信息：\n\n" + this.sourceText)
    ]
    const apiKey: string = await this.dataManager.getApiKey()
    this.summaryText = stripMarkdown(await callDeepSeekApi(apiKey, messages))
    this.isLoading = false
  }

  async handleSave(): Promise<void> {
    if (!this.summaryText.trim()) {
      promptAction.showToast({ message: "笔记内容不能为空", duration: 1500 })
      return
    }
    this.isSaving = true

    const notes: Note[] = await this.dataManager.loadNotes()
    let note: Note

    if (this.isEditMode && this.editNoteId) {
      const existing: Note | undefined = notes.find((n: Note) => n.id === this.editNoteId)
      if (existing) {
        existing.content = this.summaryText
        existing.title = this.titleText || this.summaryText.slice(0, 30)
        note = existing
      } else {
        note = new Note(Date.now().toString(), this.titleText || this.summaryText.slice(0, 30), this.summaryText)
        notes.push(note)
      }
    } else {
      note = new Note(Date.now().toString(), this.summaryText.slice(0, 30), this.summaryText)
      notes.push(note)
    }

    await this.dataManager.saveNotes(notes)
    this.isSaving = false
    promptAction.showToast({ message: "笔记已保存", duration: 1500 })
    setTimeout(() => router.back(), 800)
  }

  build(): void {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text("←").fontSize(18).fontColor("#333")
        }.width(36).height(36).backgroundColor("rgba(245,245,245,0.7)")
        .onClick(() => router.back())

        Text(this.isEditMode ? "编辑笔记" : "总结笔记")
          .fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 12 })
        Blank()

        Button(this.isSaving ? "保存中..." : "保存")
          .fontSize(14).fontColor(Color.White).backgroundColor("#4e6ef2")
          .borderRadius(8).height(36).padding({ left: 16, right: 16 })
          .enabled(!this.isSaving && !this.isLoading)
          .onClick(() => this.handleSave())
      }.width("100%").padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(36).height(36).color("#4e6ef2")
          Text("AI 正在提炼关键信息...").fontSize(14).fontColor("#999").margin({ top: 12 })
        }.width("100%").layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        if (!this.isEditMode && this.sourceText) {
          Column() {
            Text("原始内容").fontSize(13).fontWeight(FontWeight.Medium).fontColor("#666")
              .width("100%").padding({ left: 16, right: 16, top: 8, bottom: 4 })
            Scroll() {
              Text(this.sourceText).fontSize(12).fontColor("#999").width("100%").padding(12)
            }.width("100%").height(100).backgroundColor("rgba(245,245,245,0.7)").borderRadius(8)
              .margin({ left: 16, right: 16 })
          }
          Divider().margin({ top: 12, left: 16, right: 16 })
        }

        Column() {
          if (this.isEditMode) {
            Row() {
              Text("标题").fontSize(13).fontColor("#999").width(60)
              TextInput({ text: this.titleText, placeholder: "\u8F93\u5165\u7B14\u8BB0标题" })
                .layoutWeight(1).height(40).fontSize(14).backgroundColor("rgba(245,245,245,0.7)").borderRadius(8)
                .onChange((v: string) => { this.titleText = v })
            }.width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 })
            Divider().margin({ left: 16, right: 16 })
          }

          Row() {
            Text("AI \u603B\u7ED3 \u00B7 \u53EF\u7F16\u8F91").fontSize(14).fontWeight(FontWeight.Bold).fontColor("#333")
            Blank()
            if (!this.isEditMode) {
              Button("🔄 重新生成").fontSize(11).fontColor("#4e6ef2")
                .backgroundColor("transparent").height(28)
                .onClick(() => this.generateSummary())
            }
          }.width("100%").padding({ left: 16, right: 16, top: 10, bottom: 6 })

          TextArea({ text: this.summaryText })
            .width("100%").layoutWeight(1).fontSize(15)
            .backgroundColor("rgba(250,250,250,0.7)").borderRadius(0).padding(16)
            .onChange((value: string) => { this.summaryText = value })
        }.layoutWeight(1).width("100%")
      }
    }.width("100%").height("100%").backgroundImage($r("app.media.bg_editor")).backgroundImageSize(ImageSize.Cover)
  }
}
