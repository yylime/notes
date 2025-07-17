# 使用tac_plus-ng搭建aaa认证服务

**tac_plus-ng** 是一个支持 TACACS+ 和 RADIUS 协议的守护进程，主要为网络设备（如路由器和交换机）提供认证（Authentication）、授权（Authorisation）和计费（Accounting）服务。

本版本是对最初公开发布的 Cisco 源码的重大重写，同时大量基于同一发行版中的 `tac_plus` 项目构建而成。

### 主要特性

- **支持 NAS 设备特定的密钥、提示符和启用密码**  
  可为不同的 NAS（网络访问服务器）设备配置专用密钥和访问控制参数。

- **基于规则的权限分配机制**  
  通过配置规则实现灵活的用户权限控制。

- **支持灵活的外部后端用户数据库**  
  支持使用 PERL 脚本、C 语言程序等自定义后端，还内置支持 LDAP（包括 Active Directory）、RADIUS 等多种用户资料来源。

- **连接多路复用（Connection Multiplexing）**  
  支持每个进程同时处理多个 NAS 客户端连接。

- **会话多路复用（Session Multiplexing）**  
  支持在单个连接中并发多个会话，提升资源利用率。

- **高可扩展性**  
  没有用户、客户端或服务器数量限制。

- **支持 CLI 上下文感知**  
  能够感知命令行接口（CLI）中的上下文环境，以提供更智能的权限控制。

- **全面支持 IPv4 和 IPv6**

- **实现并自动识别 HAProxy 协议 v2**

- **支持 TLS 加密传输**

- **符合 RFC 8907 标准**

- **支持 Linux VRF（虚拟路由与转发）**

- **支持非标准的 SSH 公钥认证机制**  
  详见官方 Wiki 获取详细配置说明。

- **支持多种 RADIUS 协议变体的自动识别与实现**  
  包括传统 RADIUS（UDP 和 TCP）、RADSEC（基于 TLS）以及 RADIUS/DTLS（基于 DTLS），均支持 PAP 认证。


## 准备工作
### 官方参考

地址：[tacacs+ng](https://projects.pro-bono-publico.de/event-driven-servers/doc/tac_plus-ng.html)

Git: https://github.com/MarcJHuber/event-driven-servers/

### 下载

```python
git clone https://github.com/MarcJHuber/event-driven-servers.git
```

### 安装

```shell
# 进入下载后到文件
cd event-driven-servers
# complile
./configure tac_plus-ng
make
sudo make install

# 检查是否成功
/usr/local/sbin/tac_plus-ng -v
```

## 制作配置文件

通过vim或者nano生产配置文件到一个配置文件，例如 `tacacs.conf`

```shell
id = spawnd {
        # tacacs+默认端口为49，wireshark可将目的端口为49的tcp解析为tacacs+报文
        listen = { port = 49 }
        spawn = {
                instances min = 1
                instances max = 100
        }
}

id = tac_plus-ng {
        # 日志记录
        key = "cisco"
        log authentication { destination = /var/log/tac_plus/authentication/authentication.log }
        log authorization { destination = /var/log/tac_plus/authorization/authorization.log }
        log accounting  { destination = /var/log/tac_plus/accounting/accounting.log }
        log access  { destination = /var/log/tac_plus/access/access.log }
    
        authentication log = authentication
        authorization log = authorization
        accounting log = accounting
        access log = access

        # 设备描述
        device world {
                address = ::/0
                welcome banner = "\nCMG-NET yylime welcome\n\n"
                key = "cisco"
        }

        device cmg {
                address = 172.20.0.0/16
                welcome banner = "\nCMG-NET yylime welcome\n\n"
                key = "cisco"
        }
        # 用户组配置
        group = admin {
    
        }

        # 用户配置
        user = demo {
                #使用明文密码
                password login = clear demo123
                member = admin
                profile {
                    script {
                        if (service == shell) {
                            set priv-lvl = 15
                            permit
                        }
                        permit
                    }  
                }
        }

        # 规则匹配
        ruleset {
            rule from-cmg {
                enabled = yes
                script {
                    if (nas == cmg) {
                        permit
                    }
                }
            }
    }
}
```

创建日志文件夹，并且配置权限

```shell
mkdir /var/log/tac_plus/authentication
mkdir /var/log/tac_plus/authorization
mkdir /var/log/tac_plus/accounting
mkdir /var/log/tac_plus/access
sudo chmod 777 /var/log/tac_plus
```

## 检查配置，并启动服务

```shell
# 检查命令
/usr/local/sbin/tac_plus-ng -P tacacs.conf
# 前台运行
/usr/local/sbin/tac_plus-ng -f tacacs.conf
# 后台运行
/usr/local/sbin/tac_plus-ng -b tacacs.conf
```


## 交换机配置并测试

测试服务已在172.20.255.156上运行，配置后可用上面配置文件中的`demo:demo123` 测试

### H3C配置
**H3C交换机几个关键点配置（172.20.250.20为例）**

```shell showLineNumbers {8}
# tacacs config
hwtacacs nas-ip 172.20.250.20
hwtacacs scheme acs
primary authentication 172.20.255.156 key simple cisco
primary authorization 172.20.255.156 key simple cisco
primary accounting 172.20.255.156 key simple cisco
# very import the line below
user-name-format without-domain

# domain config
domain cctv
authentication login hwtacacs-scheme acs local
authorization login hwtacacs-scheme acs local
accounting login hwtacacs-scheme acs local
authorization command hwtacacs-scheme acs local
accounting command hwtacacs-scheme acs
quit
domain default enable cctv

# vty
line vty 0 4
authentication-mode scheme
user-role level-15
protocol inbound ssh
command authorization
command accounting
```

### 华为配置

```shell showLineNumbers {8}
# tacacs config
hwtacacs enable
hwtacacs-server template acs
  hwtacacs-server authentication 172.20.255.156
  hwtacacs-server authorization 172.20.255.156
  hwtacacs-server accounting 172.20.255.156 
  hwtacacs-server shared-key cipher cisco
  undo hwtacacs-server user-name domain-included
  hwtacacs-server source-ip 172.20.250.20


# aaa 认证、授权、审计
aaa
authentication-scheme acs
authentication-mode hwtacacs local

authorization-scheme acs
authorization-mode hwtacacs local

accounting-scheme acs
accounting-mode hwtacacs
accounting start-fail online
# 记录命令
recording-scheme acs
recording-mode hwtacacs acs
cmd recording-scheme acs

domain default_admin
  authentication-scheme acs
  accounting-scheme acs
  authorization-scheme acs
  hwtacacs-server acs
```