import { basename } from 'node:path'
import { defineConfig } from 'vitepress'
import MarkdownPreview from 'vite-plugin-markdown-preview'


import { head, nav, sidebar } from './configs'

const APP_BASE_PATH = basename(process.env.GITHUB_REPOSITORY || '')

export default defineConfig({
  outDir: "../dist",
  base: APP_BASE_PATH ? `/${APP_BASE_PATH}/` : "/",

  lang: "zh-CN",
  title: "小林子的小屋",
  description: "开始记录吧",
  head,

  lastUpdated: true,
  cleanUrls: true,

  /* markdown 配置 */
  markdown: {
    lineNumbers: true,
  },

  /* 主题配置 */
  themeConfig: {
    i18nRouting: false,

    logo: "/logo.png",

    nav,
    sidebar,

    /* 右侧大纲配置 */
    outline: {
      level: "deep",
      label: "目录",
    },

    socialLinks: [{ icon: "github", link: "https://github.com/yylime" }],

    footer: {
      message: "Made with ❤️ by yylime ｜ theme by maomao",
      copyright: "Copyright © 2025-present yylime",
    },

    lastUpdated: {
      text: "最后更新于",
      formatOptions: {
        dateStyle: "short",
        timeStyle: "medium",
      },
    },

    docFooter: {
      prev: "上一篇",
      next: "下一篇",
    },

    returnToTopLabel: "回到顶部",
    sidebarMenuLabel: "菜单",
    darkModeSwitchLabel: "主题",
    lightModeSwitchTitle: "切换到浅色模式",
    darkModeSwitchTitle: "切换到深色模式",

    /*** 自定义配置 ***/
    visitor: {
      badgeId: "yylime.notes",
    },

    comment: {
      repo: "yylime/notes",
      repoId: "R_kgDOPGr3hQ",
      category: "Announcements",
      categoryId: "DIC_kwDOPGr3hc4CsdwU",
    },
  },

  vite: {
    plugins: [MarkdownPreview()],
  },
});
