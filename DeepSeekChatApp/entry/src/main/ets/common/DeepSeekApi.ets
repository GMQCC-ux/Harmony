/**
 * DeepSeek API 调用模块
 * 封装与DeepSeek大语言模型的HTTP通信
 */
import http from "@ohos.net.http"
import { ChatMessage, MessageRole } from "../model/ChatData"
import { stripMarkdown } from "./TextUtil"

// DeepSeek API 配置
const DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"
const DEEPSEEK_MODEL = "deepseek-chat"

// API请求消息格式
interface ApiMessage {
  role: string
  content: string
}

// API响应内部格式
interface ChoiceMessage {
  role: string
  content: string
}

interface ApiChoice {
  message: ChoiceMessage
}

// API响应格式
interface ApiResponse {
  choices: ApiChoice[]
}

/**
 * 调用DeepSeek API发送消息并获取回复
 * @param apiKey 用户的API密钥
 * @param messages 历史消息列表
 * @returns AI回复文本
 */
export async function callDeepSeekApi(apiKey: string, messages: ChatMessage[]): Promise<string> {
  // 构建API请求体
  const apiMessages: ApiMessage[] = [
    {
      role: "system",
      content: "你是一个智能助手，请用简洁友好的方式回答用户的问题。注意：请使用纯文本回复，不要使用Markdown格式（如**粗体**、#标题、-列表、`代码块`等标记符号）。"
    }
  ]

  // 添加历史消息（最多保留最近20条）
  const recentMessages: ChatMessage[] = messages.slice(-20)
  for (const msg of recentMessages) {
    apiMessages.push({
      role: msg.role === MessageRole.USER ? "user" : "assistant",
      content: msg.content
    })
  }

  const requestBody: string = JSON.stringify({
    model: DEEPSEEK_MODEL,
    messages: apiMessages,
    temperature: 0.7,
    max_tokens: 2000
  })

  // 发送HTTP请求
  const httpRequest = http.createHttp()
  try {
    const response = await httpRequest.request(
      DEEPSEEK_API_URL,
      {
        method: http.RequestMethod.POST,
        header: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + apiKey
        },
        extraData: requestBody,
        connectTimeout: 30000,
        readTimeout: 60000
      }
    )

    if (response.responseCode === 200) {
      const result: ApiResponse = JSON.parse(response.result as string) as ApiResponse
      if (result.choices && result.choices.length > 0) {
        return stripMarkdown(result.choices[0].message.content)
      }
      return "抱歉，我暂时无法回答这个问题。"
    } else {
      return "网络请求失败（错误码：" + response.responseCode + "），请检查网络连接后重试。"
    }
  } catch (error) {
    return "网络连接异常，请检查网络设置后重试。"
  } finally {
    httpRequest.destroy()
  }
}
