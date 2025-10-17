import type { DefaultTheme } from 'vitepress'

export const nav: DefaultTheme.Config['nav'] = [
  { text: '前端导航', link: '/nav/' },
  { text: '网络', items: [
      { text: '网络自动化', link: '/network/netmiko' },
      { text: '交换机管理', link: '/network/switch-manager' }
  ]},
  { text: 'VPS', items: [
      { text: '测评', link: '/vps/list' },
      { text: '脚本', link: '/vps/singbox' }
  ]},
  { text: '小林子', link: '/xiaolinzi' },
]
