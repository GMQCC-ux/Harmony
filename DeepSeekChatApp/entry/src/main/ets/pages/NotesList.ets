import { router } from "@kit.ArkUI"
import { DataManager } from "../common/DataManager"
import { Note } from "../model/ChatData"

@Entry
@Component
struct NotesList {
  @State notes: Note[] = []
  private dataManager: DataManager = DataManager.getInstance()

  async aboutToAppear(): Promise<void> {
    this.notes = await this.dataManager.loadNotes()
  }

  async deleteNote(noteId: string): Promise<void> {
    const idx: number = this.notes.findIndex((n: Note) => n.id === noteId)
    if (idx >= 0) {
      this.notes.splice(idx, 1)
      await this.dataManager.saveNotes(this.notes)
    }
  }

  openNote(note: Note): void {
    router.pushUrl({
      url: "pages/NoteEditor",
      params: { noteId: note.id, noteContent: note.content, noteTitle: note.title }
    })
  }

  build(): void {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text("←").fontSize(18).fontColor("#333")
        }.width(36).height(36).backgroundColor("rgba(245,245,245,0.7)")
        .onClick(() => router.back())

        Text("我的笔记").fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 12 })
        Blank()
      }.width("100%").padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.notes.length === 0) {
        Column() {
          Text("📝").fontSize(48).margin({ bottom: 12 })
          Text("暂无笔记").fontSize(15).fontColor("#999")
          Text("在对话中选择消息生成总结笔记").fontSize(13).fontColor("#bbb").margin({ top: 4 })
        }.width("100%").layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.notes, (note: Note) => {
            ListItem() {
              Row() {
                Column() {
                  Text(note.title || "\u65E0标题").fontSize(15).fontColor("#333")
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(note.content.slice(0, 50) + "...").fontSize(12).fontColor("#999")
                    .maxLines(2).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                Button({ type: ButtonType.Circle }) {
                  Text("✕").fontSize(14).fontColor("#ff4d4f")
                }.width(32).height(32).backgroundColor("rgba(255,240,240,0.8)")
                .onClick(() => { this.deleteNote(note.id) })
              }.width("100%").padding({ left: 20, right: 20, top: 14, bottom: 14 })
            }
            .onClick(() => { this.openNote(note) })
          })
        }.layoutWeight(1).divider({ strokeWidth: 0.5, color: "#eee" })
      }
    }.width("100%").height("100%").backgroundImage($r("app.media.bg_notes")).backgroundImageSize(ImageSize.Cover)
  }
}
