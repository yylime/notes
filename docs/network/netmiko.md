# Netmiko

从0开始学习netmiko，官方Github的[Getting Started](https://github.com/ktbyers/netmiko/tree/develop?tab=readme-ov-file#getting-started-1)。单位交换机数量高达2000+，手动对设备进行常规维护非常耗时，我解手的时候采用的shell脚本来对交换机进行配置保存，但效率低下多线程支持不友好，于是该用netmiko，也开启对netmiko的学习之路。本篇将主要讲述使用netmiko在日常工作中遇到的问题和解决方案（设计交换机型号为Huawei、Cisco_IOS, Cisco_NXOS, H3C）。
## 安装与使用
```sh
pip install netmiko
```
查看当前运行的配置的案例
```python
from netmiko import ConnectHandler
with ConnectHandler(device_type="huawei",
                    ip="172.20.1.1",
                    username="admin",
                    password="admin",
                    conn_timeout=100, # 连接超时时间
                    fast_cli=False, # 是否使用fast_cli
                    auth_timeout=10, # 认证超时时间
                    ) as net_connect:
    # Send a command and get the output
    commond = "dis cur"
    output = net_connect.send_command(commond, read_timeout=10) # 命令执行超时时间
print(output)
```
## 常用功能

### 配置保存


### 序列号和设备型号读取

### 自动维护设备名称

### 设备接口空闲时长

### 配置比对

### 接口三层IP

### VRF（VPN-instance）统计

### 

## 常见问题

### H3C在netmiko中该使用什么型号？
该[链接](https://github.com/ktbyers/netmiko/blob/master/netmiko/ssh_dispatcher.py)给出了官方支持列表**CLASS_MAPPER_BASE**，此列表中找不到任何H3C，查询测试发现应该使用 **hp_comware**

### 华为AC交换机配置过长
通过配置 *send_command* 函数中的 *read_timeout* 参数解决。
```python
# 我的项目中使用如下行解决AC交换机配置超过几万行的问题
read_timeout = 40 if "AC6605" not in device.name else 300
```

### 