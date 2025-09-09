# sing-box
之前总是使用各种一键脚本，但是脚本需求往往很复杂，各种依赖，于是自己针对自己的需求简单写了一个用于自用。

如果你希望对sing-box有更深一步的了解参考[sing-box官方文档](https://sing-box.sagernet.org/)。
::: tip
- 用于直连优秀VPS
- 无需域名
- tls加密
- 导出配置到v2rayN
- 出站路由尽量在客户端完成
:::
::: warning
最近测试发现 `reality` 似乎工作起来并不完美
:::

## 客户端推荐
- `Widnows/MacOS`: [V2rayN](https://github.com/2dust/v2rayNG/releases)
- `Android`: [Nekobox](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) / [v2rayNG](https://github.com/2dust/v2rayNG/releases)
- `iOS`: 小火箭

## 协议选择
reality目前选择最多的tls模式，优势无需多言。默认自签名tls也是带加密的所有使用这种组合既有TCP又有UDP，兼容速度。
- vless + reality
- hysteria2 + 自签名tls
## 安装使用

具体使用
```shell
bash <(curl -fsSL https://raw.githubusercontent.com/yylime/notes/main/docs/vps/public/singbox.sh)
```
