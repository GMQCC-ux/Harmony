/**
 * 数据持久化管理模块
 * 使用Preferences存储用户数据和聊天记录
 */
import { preferences } from "@kit.ArkData"
import { Conversation, ChatMessage, MessageRole } from "../model/ChatData"
import { Note } from "../model/ChatData"

const STORE_NAME: string = "deepseek_chat_store"

const KEY_USERNAME: string = "saved_username"
const KEY_PASSWORD: string = "saved_password"
const KEY_REMEMBER: string = "remember_password"
const KEY_IS_LOGGED_IN: string = "is_logged_in"
const KEY_CONVERSATIONS: string = "conversations"
const KEY_NOTES: string = "notes"
const KEY_API_KEY: string = "api_key"
const KEY_USERS: string = "users"

// 返回类型接口
interface RememberedLogin {
  username: string
  password: string
  remember: boolean
}

// JSON解析辅助接口
interface ConvData {
  id: string
  title: string
  createTime: number
  updateTime: number
  messages: MsgData[]
}

interface MsgData {
  id: string
  role: MessageRole
  content: string
  timestamp: number
}

interface NoteData {
  id: string
  title: string
  content: string
  createTime: number
}

// 用户数据接口
interface UserData {
  username: string
  password: string
}

export class DataManager {
  private static instance: DataManager | null = null
  private store: preferences.Preferences | null = null

  static getInstance(): DataManager {
    if (!DataManager.instance) {
      DataManager.instance = new DataManager()
    }
    return DataManager.instance!
  }

  async init(context: Context): Promise<void> {
    this.store = await preferences.getPreferences(context, STORE_NAME)
  }

  async login(username: string, password: string): Promise<boolean> {
    const users: UserData[] = await this.getUsers()
    const found: UserData | undefined = users.find((u: UserData) => u.username === username && u.password === password)
    const valid: boolean = found !== undefined
    if (valid) {
      await this.store!.put(KEY_IS_LOGGED_IN, true)
      await this.store!.put(KEY_USERNAME, username)
      await this.store!.flush()
    }
    return valid
  }

  async register(username: string, password: string): Promise<boolean> {
    const users: UserData[] = await this.getUsers()
    const exists: boolean = users.some((u: UserData) => u.username === username)
    if (exists) {
      return false
    }
    users.push({ username: username, password: password })
    await this.store!.put(KEY_USERS, JSON.stringify(users))
    await this.store!.flush()
    return true
  }

  async getUsers(): Promise<UserData[]> {
    const data: string = await this.store!.get(KEY_USERS, '[{"username":"admin","password":"123456"}]') as string
    return JSON.parse(data) as UserData[]
  }

  async saveRememberPassword(username: string, password: string, remember: boolean): Promise<void> {
    await this.store!.put(KEY_REMEMBER, remember)
    if (remember) {
      await this.store!.put(KEY_USERNAME, username)
      await this.store!.put(KEY_PASSWORD, password)
    } else {
      await this.store!.delete(KEY_USERNAME)
      await this.store!.delete(KEY_PASSWORD)
    }
    await this.store!.flush()
  }

  async getRememberedLogin(): Promise<RememberedLogin> {
    const remember: boolean = await this.store!.get(KEY_REMEMBER, false) as boolean
    const username: string = await this.store!.get(KEY_USERNAME, "") as string
    const password: string = await this.store!.get(KEY_PASSWORD, "") as string
    const result: RememberedLogin = {
      username: username,
      password: password,
      remember: remember
    }
    return result
  }

  async isLoggedIn(): Promise<boolean> {
    return await this.store!.get(KEY_IS_LOGGED_IN, false) as boolean
  }

  async logout(): Promise<void> {
    await this.store!.put(KEY_IS_LOGGED_IN, false)
    await this.store!.flush()
  }

  async saveConversations(conversations: Conversation[]): Promise<void> {
    const data: string = JSON.stringify(conversations)
    await this.store!.put(KEY_CONVERSATIONS, data)
    await this.store!.flush()
  }

  async loadConversations(): Promise<Conversation[]> {
    const data: string = await this.store!.get(KEY_CONVERSATIONS, "[]") as string
    const parsed: ConvData[] = JSON.parse(data) as ConvData[]
    const conversations: Conversation[] = []
    for (const item of parsed) {
      const conv: Conversation = new Conversation(item.id, item.title)
      conv.createTime = item.createTime
      conv.updateTime = item.updateTime
      if (item.messages) {
        for (const m of item.messages) {
          const msg: ChatMessage = new ChatMessage(m.id, m.role, m.content)
          msg.timestamp = m.timestamp
          conv.messages.push(msg)
        }
      }
      conversations.push(conv)
    }
    return conversations
  }

  async saveNotes(notes: Note[]): Promise<void> {
    const data: string = JSON.stringify(notes)
    await this.store!.put(KEY_NOTES, data)
    await this.store!.flush()
  }

  async loadNotes(): Promise<Note[]> {
    const data: string = await this.store!.get(KEY_NOTES, "[]") as string
    const parsed: NoteData[] = JSON.parse(data) as NoteData[]
    const notes: Note[] = []
    for (const item of parsed) {
      const note: Note = new Note(item.id, item.title, item.content)
      note.createTime = item.createTime
      notes.push(note)
    }
    return notes
  }

  async saveApiKey(key: string): Promise<void> {
    await this.store!.put(KEY_API_KEY, key)
    await this.store!.flush()
  }

  async getApiKey(): Promise<string> {
    return await this.store!.get(KEY_API_KEY, "") as string
  }

  async hasApiKey(): Promise<boolean> {
    const key: string = await this.getApiKey()
    return key.length > 0
  }
}
