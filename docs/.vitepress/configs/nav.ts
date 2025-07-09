import type { DefaultTheme } from 'vitepress'

export const nav: DefaultTheme.Config['nav'] = [
  { text: '前端导航', link: '/nav/' },
  { text: '网络', items: [
      { text: '网络自动化', link: '/network/netmiko' }
  ]},
  { text: 'VPS', items: [
      { text: 'bandwagon', link: '/vps/bandwagon' },
      { text: 'V.PS', link: '/vps/vps' },
      { text: 'VMISS', link: '/vps/vmiss' }
  ]},
  { text: '小林子', link: '/xiaolinzi' },
]
