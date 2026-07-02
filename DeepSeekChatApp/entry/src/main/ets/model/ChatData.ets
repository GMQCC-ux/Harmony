/**
 * 聊天消息数据模型
 * 定义单条消息和会话的数据结构
 */

// 消息角色类型
export enum MessageRole {
  USER = 'user',
  ASSISTANT = 'assistant',
  SYSTEM = 'system'
}

// 单条聊天消息
export class ChatMessage {
  id: string = ''
  role: MessageRole = MessageRole.USER
  content: string = ''
  timestamp: number = 0

  constructor(id: string, role: MessageRole, content: string) {
    this.id = id
    this.role = role
    this.content = content
    this.timestamp = Date.now()
  }
}

// 对话会话
export class Conversation {
  id: string = ''
  title: string = ''
  messages: ChatMessage[] = []
  createTime: number = 0
  updateTime: number = 0

  constructor(id: string, title: string) {
    this.id = id
    this.title = title
    this.createTime = Date.now()
    this.updateTime = Date.now()
    this.messages = []
  }
}

// 拓展功能项
export interface ExtendFeature {
  id: string
  name: string
  icon: string
  description: string
  prompt: string
}

// 预定义拓展功能列表
export const EXTEND_FEATURES: ExtendFeature[] = [
  {
    id: 'translate',
    name: '智能翻译',
    icon: '📝',
    description: '多语言实时翻译',
    prompt: '请将以下内容翻译成英文：'
  },
  {
    id: 'summary',
    name: '文本摘要',
    icon: '📋',
    description: '一键生成内容摘要',
    prompt: '请用简洁的语言总结以下内容：'
  },
  {
    id: 'code',
    name: '代码生成',
    icon: '💻',
    description: '根据需求生成代码',
    prompt: '请根据以下需求编写代码：'
  },
  {
    id: 'polish',
    name: '文案润色',
    icon: '✨',
    description: '优化文案表达',
    prompt: '请润色优化以下文案，使其更加优美流畅：'
  },
  {
    id: 'qa',
    name: '知识问答',
    icon: '🎓',
    description: '回答各类知识问题',
    prompt: '请回答以下问题：'
  },
  {
    id: 'creative',
    name: '创意写作',
    icon: '🎨',
    description: '辅助创意内容生成',
    prompt: '请根据以下主题进行创意写作：'
  }
]

/**
 * 总结笔记数据模型
 */
export class Note {
  id: string = ""
  title: string = ""
  content: string = ""
  sourceMsgIds: string[] = []
  createTime: number = 0

  constructor(id: string, title: string, content: string) {
    this.id = id
    this.title = title
    this.content = content
    this.createTime = Date.now()
    this.sourceMsgIds = []
  }
}
