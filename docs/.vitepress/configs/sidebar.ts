import type { DefaultTheme } from 'vitepress'

export const sidebar: DefaultTheme.Config['sidebar'] = {
    '/network/': [
        {
            text: '网络自动化',
            items: [
                { text: 'Netmiko', link: '/network/netmiko' },
                { text: '3a认证服务器', link: '/network/tacas-ng' },
                { text: '使用Rust连接交换机', link: '/network/rust' }
            ]
        }
    ],
    '/life/': [
        {
            text: '生活随笔',
            items: [
                { text: '日常记录', link: '/life/daily' },
                { text: '个人感悟', link: '/life/reflection' }
            ]
        }
    ],
    '/vps/': [
        {
            text: 'VPS',
            items: [
                { text: '汇总', link: '/vps/list' },
                { text: 'bandwagon', link: '/vps/bandwagon' },
                { text: 'V.PS', link: '/vps/vps' },
                { text: 'VMISS', link: '/vps/vmiss' },
            ]
        },
        {
            text: 'Proxy Script',
            items: [
                { text: 'sing-box', link: '/vps/singbox' },
            ]
        }
    ]
}
