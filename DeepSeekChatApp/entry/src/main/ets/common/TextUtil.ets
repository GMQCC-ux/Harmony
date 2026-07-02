/**
 * 文本工具 — 清洗AI输出中的Markdown格式标记
 */

/**
 * 去除Markdown格式标记，转为纯文本
 * @param text 原始文本
 * @returns 清洗后的纯文本
 */
export function stripMarkdown(text: string): string {
  if (!text) return ""
  let result: string = text
  // 去粗体 **text** 和 __text__
  result = result.replace(/\*\*(.+?)\*\*/g, "$1")
  result = result.replace(/__(.+?)__/g, "$1")
  // 去斜体 *text* 和 _text_
  result = result.replace(/\*(.+?)\*/g, "$1")
  result = result.replace(/_(.+?)_/g, "$1")
  // 去行首 ### ## # 标题标记
  result = result.replace(/^#{1,6}\s+/gm, "")
  // 去反引号 `code`
  result = result.replace(/`(.+?)`/g, "$1")
  // 去无序列表标记 - * +
  result = result.replace(/^[\-\*\+]\s+/gm, "· ")
  // 去有序列表标记 1. 2.
  result = result.replace(/^\d+\.\s+/gm, "")
  // 去 > 引用标记
  result = result.replace(/^>\s?/gm, "")
  // 去 ~~删除线~~
  result = result.replace(/~~(.+?)~~/g, "$1")
  // 去水平线 --- ***
  result = result.replace(/^[\-\*\_]{3,}\s*$/gm, "")
  // 去多余空行（连续3行以上空行压为2行）
  result = result.replace(/\n{3,}/g, "\n\n")
  return result.trim()
}
