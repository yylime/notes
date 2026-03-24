# 交换机配置管理Web服务

::: tip
当前项目属于一个学习项目，其实主要是学习一下前后端分离的项目如何写，加上工作后刚好负责网络运维部分工作，基于Django写了内部的项目，功能比当前肯定丰富。随着AI编程的兴起，就打算结合免费AI将部分核心功能做一个基础的Demo加深学习，本项目结合了一些实际工作中的运维经验，希望能实际工作中对提高运维效率和运维自动化开发学习有所帮助。
:::
### 项目背景
当前系统内交换机数量大概有2k多台，网络架构走的MPLS-VPN，设备主要涉及思科、华为、华三等厂家。虽然各厂家现在主推各自的云管平台，都实现了配置下发、对比等等核心功能，但是不同厂商之间的适配度其实不是很好，并且运维内部肯定希望将自己的一些工作经验（工单自动化、设备统计、配置对比、告警分析等等）加入到自动化当中，所以单独开发一个配置管理工具是有一定的作用的。

**主要参考并使用的开源项目**

主要是将shadcn的ui替换为full-stack-fastapi-template中的frontend，然后借助netmiko实现了主要功能。
- https://github.com/fastapi/full-stack-fastapi-template
- https://github.com/satnaing/shadcn-admin


[Switch Manager](https://github.com/yylime/switch-manager)是一个基于 FastAPI 和 React 的全栈应用程序，用于管理和监控网络交换机配置。


**项目前的一些思考**

- 这不是一个监控工具，监控当前主流zabbix+grafana是一个不错的选择。
- 设备登录认证主流应该还是aaa服务器，本项目中的巡检账号的权限也是要特别注意。
- 这也不是一个ssh工具，webssh和webtelnet实现并不复杂，你可以轻松的将其加入本项目。
- 备份的时间选择当前是每天保留一份，但我看类似的项目中保存很多，优雅的保存应该是如果配置没有发生变化，那么可以保存一个指针指向上一次的配置即可


## 功能
::: warning
当前测试的设备型号cisco_ios、cisco_nxos、hp_comware（华三）、huawei（CE系列和S系列），以上几种型号下列功能都支持，如果您的设备型号不在上述其中，您可以手动进行代码的卡法，后续给出代码所在具体位置。
:::
**已经实现的功能**
- 交换机批量导入和导出，巡检账号、分址自动创建，配置查看
- 三种定时任务，全量备份、仅备份失败（部分设备每天开关机）、ARP刷新
- IP表、VRF、ARP表信息生成
- 每日配置变更和自定义设备配置对比
- 巡检账号和分址自定义管理
- 设备型号自动识别

**尚未完成的功能**
- 后台运行日志前端展示
- webssh开发
- ...


## Quick Start

### 初始化项目
强烈建议手动学习项目环境搭建，虽然当前Docker很方便（但如果纯内外部署代理配置也比较复杂），但是有很多小的问题解决起来不如本地环境舒服，当然这只是个人的建议。
#### 前置环境
官网的脚本足够支持您安装本项目的所有依赖：
1. [postgresql](https://www.postgresql.org/download/)
2. pythong管理 [uv](https://uv.doczh.com/getting-started/installation/)
3. [node.js](https://nodejs.org/en/download)

#### 全局配置
全局配置文件 `.env`，由于没有开启Email配置，所以仅需配置如下内容，项目开始前应该创建好数据库。
```
# Backend
SECRET_KEY=yylime
FIRST_SUPERUSER=admin@admin.com
FIRST_SUPERUSER_PASSWORD=admin@123
# Postgres
POSTGRES_SERVER=db
POSTGRES_PORT=5432
POSTGRES_DB=app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```
#### 后端
```sh
cd backend
# 创建python虚拟环境
uv sync
# 启动后端
source .venv/bin/activate
fastapi dev app/main.py
```
#### 前端
这里要注意开发环境要配置 `frontend/.env`中的 `VITE_API_URL=http://localhost:8000`。同时注意 `frontend/openapi-ts.config.ts`中`input`和后端API端口一致。
```sh
cd frontend
# 我习惯使用pnpm
npm install -g pnpm
# 安装依赖
pnpm install
# openapi生成
pnpm generate-client
# 启动
pnpm run dev
```
然后您可以使用`.env`中的账号密码来访问前端 `http://localhost:5173`


## 简要开发指南

### 交换机型号检测
`backend/app/services/switches/config/stype_detect.py` 中的 `StypeDetect.best_match()` 方法实现了系统常用的型号检测，您可以自行考虑新增。也增加了`netmiko`的`SSHDetect`，它支持很多型号，也支持本项目实现的，但是它要遍历不同的厂商速度会慢并且仅支持ssh，所以这里优先使用手动实现的检测逻辑。核心逻辑如下

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
def paramiko_detect_stype(
    ip: str, username: str, password: str, login_type="ssh", port=22
) -> str | None:
    try:
        detector = StypeDetect(ip, username, password, login_type, port)
        res = detector.best_match()
        if res is None:
            # try netmiko autodetect
            remote_device = {
                "device_type": "autodetect",
                "host": ip,
                "username": username,
                "password": password,
                "port": port
            }
            res = SSHDetect(remote_device).autodetect()
        return res
    except Exception as e:
        logging.info(f"[!] Detect failed for {ip}: {e}")
        return None
```
### 定时任务开发
### 配置对比
### 定时任务
### ARP开发
### VRF开发