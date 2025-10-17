# 交换机配置管理Web服务

::: tip
当管理的交换机数据足够多的时候，交换机配置的管理尤为重要，设备替换、了解每日网络配置的变更、查询IP对应的交换机等信息都离不开交换机的配置。
:::

基于此，在单位自开发的原系统上，我将核心功能重写，[Switch Manager](https://github.com/yylime/switch-manager)是一个基于 FastAPI 和 React 的全栈应用程序，用于管理和监控网络交换机配置。系统支持自动备份交换机配置、分析配置数据、生成网络信息报告等功能。

## 功能

### 1. 交换机管理
- 交换机信息录入和管理
- 支持批量导入交换机信息（CSV格式）
- 支持多种厂商设备（华为、思科、H3C）
- 支持SSH/Telnet连接方式
- 巡检账号管理

### 2. 配置备份与分析
- 自动定时备份交换机配置
- 配置变更对比（diff）
- 配置历史版本管理
- 配置文件存储与检索

### 3. 网络数据生成
- 自动生成IP表信息
- VRF（Virtual Routing and Forwarding）信息提取
- ARP表信息收集


## 开发指南

### 连接方式
项目基于默认端口，即 **ssh:22 telnet:23**进行连接，如果有需要请自动修改，涉及文件如下：

- `backend/app/models.py`
- `backend/app/switches/config/backup.py`

### 交换机型号检测
`backend/app/switches/stype_detect.py` 中的 `StypeDetect.best_match()` 方法你可以自行修改以适配更多的型号。
```python
class StypeDetect:
    def best_match(self) -> str:
        commands = ["display version\n", "show version\n", "version\n"]
        for cmd in commands:
            stype = None
            res = self.send_commond(cmd)
            if "huawei" in res.lower():
                stype = "huawei"
            elif "H3C" in res or "h3c" in res.lower():
                stype = "hp_comware"
            elif (
                "Cisco IOS Software" in res
                or "Cisco Internetwork Operating System Software" in res
            ):
                stype = "cisco_ios"
            elif "NX-OS" in res or "Cisco Nexus Operating System" in res or "NOS-CN" in res:
                stype = "cisco_nxos"
            elif "Fabric OS" in res:
                stype = "brocade_fos"
            if stype:
                self.close()
                return stype
        return "cisco_ios"
```
