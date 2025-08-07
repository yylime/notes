# Netmiko 自动化

从0开始学习netmiko，开始学习前建议浏览官方Github的[Getting Started](https://github.com/ktbyers/netmiko/tree/develop?tab=readme-ov-file#getting-started-1)。单位交换机数量高达2000+，手动对设备进行常规维护非常耗时，我接手的时候采用的shell脚本来对交换机进行配置保存，效率低下并且多线程支持不友好，于是改用netmiko，也开启对netmiko的学习之路。本篇将主要讲述使用netmiko在日常工作中遇到的问题和解决方案（涉及交换机型号为Huawei、Cisco_IOS, Cisco_NXOS, H3C）。

## 安装与使用
```sh
pip install netmiko
```
一个输出查看华为交换机当前配置的例子如下，更多的案例可以参考 [Netmiko Examples](https://github.com/ktbyers/netmiko/blob/develop/EXAMPLES.md)
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

netmiko 很多的数据提取会借助 [TextFSM](https://github.com/google/textfsm)，它可以有效的提取返回数据的格式化数据，netmiko集成很多模板可以直接使用，模板来自[ntc-templates](https://github.com/networktocode/ntc-templates)，使用自带模板的一个案例如下：
```python
from netmiko import ConnectHandler
from pprint import pprint

cisco1 = {
    "device_type": "cisco_ios",
    "host": "172.20.1.1",
    "username": "pyclass",
    "password": "secret",
}

command = "show ip int brief"
with ConnectHandler(**cisco1) as net_connect:
    # Use TextFSM to retrieve structured data
    output = net_connect.send_command(command, use_textfsm=True)

print()
pprint(output)
print()
```

### 配置保存
核心代码逻辑如下
```python
with ConnectHandler(
            device_type=device_type,
            ip=connect_ip,
            username=device.inspector.name,
            password=device.inspector.password,
            conn_timeout=100,
            fast_cli=False,
            auth_timeout=10,
        ) as net_connect:
    # 为了保证下载的配置是完整的，我们需要对结尾进行判断
    # 部分华为设备的配置太长需要增加读取延时
    read_timeout = 40 if "AC6605" not in device.name else 300
    if "cisco" not in device_type:
        commond = "display current-configuration"
        if "S5735" in device.name or "S5736" in device.name:
            output = net_connect.send_command(
                commond, read_timeout=read_timeout
            )
        else:
            output = net_connect.send_command(
                commond, read_timeout=read_timeout, expect_string="return"
            )
        # 正则提取H3C的配置，华为和思科没有这个问题
        if device.stype == "hp_comware":
            match = re.search(r"#.*?return", output, re.DOTALL)
            if match:
                matched_text = match.group(0)
                output = matched_text
    else:
        commond = "show running-config"
        output = net_connect.send_command(commond, read_timeout=read_timeout)
```
### 序列号和设备型号读取
这里分享一下不同型号设备的 **TextFSM** 模板
::: code-group

``` [cisco_ios]
Value Required NAME ([0-9]+|Switch System|Switch [0-9]+|CISCO3945-CHASSIS|CISCO7606-S|Chassis|WS-C6509-E)
Value Required SN (\S+)

Start
  ^NAME: "${NAME}",\s+DESCR: [\S\s]+
  ^PID: [\S\s]+ VID: [\S\s]+ SN: ${SN} -> Record
```

```plain [cisco_nxos]
Value Required NAME (Chassis|chassis)
Value Required SN ([A-Z0-9]{10,20})

Start
  ^NAME:\s+"Chassis",\s+DESCR:[\S\s]+${NAME}.* -> readsn

readsn
  ^PID: [\S\s]+ VID: [\S\s]+ SN: ${SN} -> Record
  ^.* -> Start
```

``` [huawei]
Value Required NAME ([0-9]+|backplane)
Value Required SN ([A-Z0-9]{12,20})

Start
  ^${NAME}[\S\s]+-[\S\s]+ ${SN} -> Record
```

``` [h3c]
Value Required NAME ([\S]+)
Value Required SN (\S+)

Start
  ^\s*(Slot [0-9]+|Chassis self).*: -> readsn
  
readsn
  ^\s*DEVICE_NAME\s+: ${NAME}
  ^\s*DEVICE_SERIAL_NUMBER : ${SN} -> Record
  ^.* -> Start
```
:::

这里给出一个测试后使用的案例
```python
def read_switch_sn(net_connect: ConnectHandler, device: Switch, force=False) -> dict:
    
    if len(device.SN) > 1 and not force:
        return {"status": "error", "output": "已经存在SN"}

    textfsm_stype = device.stype
    
    commond_map = {
        "huawei" : "dis device manufacture-info", 
        "cisco_ios" : "show inventory",
        "cisco_nxos" : "show inventory",
        "hp_comware": "dis device manuinfo",
        "brocade_fos": "chassisshow"
    }

    sn_textfsm_path = {
        "huawei" : "nms/utils/fsmTemplates/sn/huawei_sn.textfsm", 
        "huawei_ac" : "nms/utils/fsmTemplates/sn/huawei_ac_sn.textfsm", 
        "cisco_ios" : "nms/utils/fsmTemplates/sn/cisco_sn.textfsm",
        "cisco_nxos" : "nms/utils/fsmTemplates/sn/cisco_nxos_sn.textfsm",
        "hp_comware": "nms/utils/fsmTemplates/sn/h3c_sn.textfsm",
        "brocade_fos": "nms/utils/fsmTemplates/sn/brocade_fos.textfsm",
    }

    # 剔除非交换机的序列号    
    withouts = ["LSXM", "ES0W", "PAC6"]
    # 接受连接器
    read_timeout = 10
    output = net_connect.send_command(commond_map[device.stype], read_timeout=read_timeout)
    if "Error" in output and device.stype == "huawei":
        output = net_connect.send_command("dis device elabel brief", read_timeout=read_timeout)
    # 特殊处理华为部分交换机
    if "Error" in output and device.stype == "huawei":
        if "NE40-" in device.name:
            cmd = "dis elabel backplane"
        else:
            cmd = "dis elabel brief"
        output = net_connect.send_command(cmd, read_timeout=read_timeout)
        textfsm_stype = "huawei_ac"
        
    # 检查ouput的合法性
    if  not "Error" in output:
        with open(sn_textfsm_path[textfsm_stype]) as f:
            re_table = textfsm.TextFSM(f)
        sns = re_table.ParseText(output)

        # 预处理不同型号
        if "C6509" in output or "CE12804-AC" in output or "backplane" in output and ("S7706" not in device.name):
            sns = [i for i in sns if i[0] not in set([str(k) for k in range(20)])]
        # 删除非board的值
        if device.stype == "brocade_fos":
            brocade_fos_withouts = ["AGB", "ANN", "ANQ", "AGC", "CBG", "BQD"]
            SN = ";".join([l[1] for l in sns if not any(l[1].startswith(w) for w in brocade_fos_withouts)])
        else:
            SN = ";".join([l[1] for l in sns if not any(l[0].startswith(w) for w in withouts)])

        stack = len(SN.split(";"))
        if device.SN != SN:
            device.SN = SN
            device.stack = stack
            device.save()

        return {"status": "success", "output": SN}
    
    return {"status": "error", "output": "读取序列号失败"}
```

### 自动维护设备名称
```python
def updated_switch_hostname(switch: Switch, res: dict) -> bool:
    output = res["output"] # 这是配置输出
    if res["status"] == "success" and output != "null":
        # 正则表达式读取配置中的文件名
        pattern = re.compile(r"(?:sysname|hostname)\s+(.*)")
        # 在配置中查找匹配项
        matches = pattern.findall(output)
        if len(matches) > 0:
            switch.name = matches[0]
            switch.save()
            return True
    return False
```

### 设备接口空闲时长
由于设备众多，经常需要对接入设备的接口进行开通或调整，于是写了一个用于提取交换机接口多久未使用的模板，定期将数据存储到数据库便于查询，此部分也须借助 **TextFSM** 模块来实现。

::: code-group
``` [cisco_ios.textfsm]
Value Required INTERFACE (.*Eth\S+)
Value LINK_STATUS (.+?)
Value PROTOCOL_STATUS (.+?)
Value LAST_INPUT (.+?)
Value LAST_OUTPUT (.+?)
Value LAST_OUTPUT_HANG (.+?)

Start
  ^\S+\s+is\s+.+?,\s+line\s+protocol.*$$ -> Continue.Record
  ^${INTERFACE}\s+is\s+${LINK_STATUS},\s+line\s+protocol\s+is\s+${PROTOCOL_STATUS}\s*$$
  ^\s+Last\s+input\s+${LAST_INPUT},\s+output\s+${LAST_OUTPUT},\s+output\s+hang\s+${LAST_OUTPUT_HANG}\s*$$\s*$$
  ^Load\s+for\s+
  ^Time\s+source\s+is
```

``` [huawei.textfsm]
Value Required INTERFACE (.*Ether\S+|GE\S+)
Value LINE_STATUS (UP|DOWN|Administratively DOWN)
Value PROTOCOL_STATUS (UP(\(spoofing\))?|DOWN)
Value PORT_LINK_TYPE (\S+)
Value VLAN_NATIVE (\d+)
Value UP_TIME (\S+\s\S+)
Value DOWN_TIME (\S+\s\S+)

Start
  ^\s*${INTERFACE} current state : ${LINE_STATUS}
  ^\s*.* protocol.*: ${PROTOCOL_STATUS}
  ^\s*.*Link-type : ${PORT_LINK_TYPE}(configured),
  ^\s*PVID :  ${VLAN_NATIVE},.*
  ^\s*Last physical up.*: ${UP_TIME}.*
  ^\s*Last physical down.*: ${DOWN_TIME}.*
  ^(#|!|\s*$$) -> Record
```

``` [h3c.textfsm]
Value Required INTERFACE (.*gabit\S+)
Value LINE_STATUS (UP|DOWN|Administratively DOWN)
Value PROTOCOL_STATUS (UP(\(spoofing\))?|DOWN)
Value PORT_LINK_TYPE (\S+)
Value UNTAGGED_VLAN_ID (\d+)
Value VLAN_NATIVE (\d+)
Value List VLAN_PASSING ([^,]+)
Value List VLAN_PERMITTED ([^,]+)
Value UP_TIME (\S+\s\S+)
Value DOWN_TIME (\S+\s\S+)

Start
  ^\s*${INTERFACE}$$
  ^\s*Current\s+state:\s+${LINE_STATUS}
  ^\s*${INTERFACE}\s+current\s+state\s*:\s*${LINE_STATUS}
  ^\s*Line\s+protocol\s+state:\s+${PROTOCOL_STATUS}
  ^\s*Line\s+protocol\s+current\s+state:\s+${PROTOCOL_STATUS}
  ^\s*PVID:\s+${VLAN_NATIVE}
  ^\s*Port\s+link-type:\s+${PORT_LINK_TYPE}
  ^\s*Un[Tt]agged\s+VLAN\s+ID\s*:\s*${UNTAGGED_VLAN_ID}
  # Trunk - Passing VLANs (parsing multiple times with Continue)
  ^\s+VLAN\s+[Pp]assing\s*:\s+${VLAN_PASSING},* -> Continue
  # Skip initial VLANs and read the Nth + 1
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){1}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){2}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){3}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){4}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){5}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){6}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){7}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){8}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){9}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){10}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){11}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){12}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){13}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){14}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){15}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){16}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){17}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){18}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){19}\s+${VLAN_PASSING},* -> Continue
  ^\s+VLAN\s+[Pp]assing\s*:(?:\s+[^,]+,){20}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){1}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){2}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){3}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){4}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){5}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){6}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){7}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){8}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){9}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){10}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){11}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){12}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){13}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){14}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){15}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){16}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){17}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){18}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){19}\s+${VLAN_PASSING},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){20}\s+${VLAN_PASSING},* -> Continue
  # End of VLAN Passing
  ^\s+VLAN\s+[Pp]assing\s*:
  ^\s{14,}
  # Trunk - Permitted VLANs (parsing multiple times with Continue)
  ^\s+VLAN\s+permitted:\s+${VLAN_PERMITTED},* -> Continue
  # Skip initial VLANs and read the Nth + 1
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){1}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){2}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){3}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){4}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){5}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){6}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){7}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){8}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){9}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){10}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){11}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){12}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){13}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){14}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){15}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){16}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){17}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){18}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){19}\s+${VLAN_PERMITTED},* -> Continue
  ^\s+VLAN\s+permitted:(?:\s+[^,]+,){20}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){1}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){2}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){3}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){4}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){5}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){6}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){7}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){8}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){9}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){10}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){11}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){12}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){13}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){14}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){15}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){16}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){17}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){18}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){19}\s+${VLAN_PERMITTED},* -> Continue
  ^\s{14,}(?:\s+[^,]+,){20}\s+${VLAN_PERMITTED},* -> Continue
  # End of VLAN Passing
  ^\s+VLAN\s+permitted:
  ^\s{14,}
  # up and down time
  ^\s*Last time when physical state changed to up:${UP_TIME}.*
  ^\s*Last time when physical state changed to down:${DOWN_TIME}.*
  ^(#|!|\s*$$) -> Record
```
:::


### 接口三层IP
这里将不同型号设备的接口三层IP进行统一处理，使用同一个TextFSM进行解析，并生成对应的数据。
```textfsm [show_run.textfsm]
Value Required Interface (\S+)
Value Required IP (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})
Value MSK (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|[0-9]{1,2})
Value VRF (\S+)
Value ACL (\S+)
Value Status (shutdown)

Start
  ^interface\s+${Interface}
  ^\s{0,10}(?:ip vrf forwarding|vrf member|ip binding vpn-instance|vrf forwarding) ${VRF}
  ^\s*ip access-group ${ACL} in
  ^\s{0,10}ip address ${IP}(\s+|/+)${MSK}$$
  ^\s{0,10}${Status}
  ^(#|!|\s*$$) -> Record
```
使用案例，这里保存为`json`
```python
def build_ip_interface():
    today = datetime.datetime.today()
    cfgs = SwitchConfig.objects.filter(created__gte=today) # 改为自己的配置文件
    res = []
    for cfg in cfgs:
        # 基于状态机的算法，每次都需要重新初始化
        with open("nms/utils/fsmTemplates/show_run.textfsm") as f:
            re_table = textfsm.TextFSM(f)
        data = re_table.ParseText(cfg.get_config())
        for interface, ip, mask, vrf, acl, status in data:
            res.append(
                (cfg.switch.name, interface, ip, cal_mask_len(mask), vrf, acl, status)
            )
    with open("nms/data/iptables.json", "w") as f:
        json.dump(res, f)
```

### VRF（vpn-instance）统计
很多查询过程会用的vrf，所以每天也会对vrf进行统计，方便查询。我们的`PE`设备都是思科nxos系列的，所以TextFSM模板如下：
```plaintext
Value Required VRF (\S+)
Value Required RD ([0-9]+\:[0-9]+)
Value Required RT ([0-9]+\:[0-9]+)

Start
  ^(ip vrf|vrf context) ${VRF}
  ^\s+rd ${RD}
  ^\s+route-target export ${RT} -> Record
```

运行中的案例，我这里存储用的书数据库，django的orm模型。
```python
def update_vrf_tables():
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    cfgs = SwitchConfig.objects.filter(created__gte=today, status="success")
    for cfg in cfgs:
        with open("nms/utils/fsmTemplates/vrf.textfsm") as f:
            re_table = textfsm.TextFSM(f)
        data = re_table.ParseText(cfg.get_config())
        if len(data) > 0:
            for vrf, rd, rt in data:
                vrfs = VRF.objects.filter(rd=rd)
                if len(vrfs) == 0:
                    VRF.objects.create(name=vrf, rd=rd, rt=rt)
```

### ARP和对应接口
这里的`cisco`其实涉及两个步骤，一个是获取ARP表（***show ip art***），一个是获取对应接口（***show mac-address-table***），H3C和华为则只需要获取ARP表（***dis arp***）。
> [!TIP]
> - 华为S系列的ARP表的比较特别，vlan号在下一行需要逐行解析
> - 我们对于直接的三层接口的需求其实不大，因为我们可以直接定位到接口，这里不做处理

::: code-group
```python [cisco_ios.py]
def parse_cisco_arp(arp_text: str, mac_text: str):
    # arp_text 对应的ARP表
    # mac_text 对应的MAC表
    pattern = re.compile(
        r"Internet\s+(\d+\.\d+\.\d+\.\d+)\s+\S+\s+([\da-f\.]+)\s+ARPA\s+Vlan(\d+)",
        re.IGNORECASE
    )
    results = []

    for match in pattern.finditer(arp_text):
        ip = match.group(1)
        mac = match.group(2).lower()
        vlan = match.group(3)
        results.append({
            "ip": ip,
            "mac": mac,
            "vlan": vlan
        })
        
    pattern = re.compile(r"\s*\d+\s+([\da-f\.]+)\s+\S+\s+(\S+)", re.IGNORECASE)
    mac_to_interface = {}

    for match in pattern.finditer(mac_text):
        mac = match.group(1).lower()
        interface = match.group(2)
        mac_to_interface[mac] = interface

    for entry in results:
        mac = entry["mac"]
        if mac in mac_to_interface:
            entry["interface"] = mac_to_interface[mac]

    return results
```

```python [cisco_nxos.py]
def parse_nxos_arp_table(arp_text: str, mac_text: str) -> List[Dict[str, str]]:
    """
    解析 NX-OS 的 'show ip arp' 输出，提取 IP、MAC、VLAN 信息。
    仅当接口为 VlanXXX 时才提取 VLAN。

    返回: List[Dict]，每条记录包含: ip, mac, vlan
    """
    results = []

    pattern = re.compile(
        r"(\d+\.\d+\.\d+\.\d+)\s+\d{2}:\d{2}:\d{2}\s+([\da-f\.]+)\s+(\S+)",
        re.IGNORECASE
    )

    for match in pattern.finditer(arp_text):
        ip = match.group(1)
        mac = match.group(2).lower()
        interface = match.group(3)
        vlan_match = re.match(r"Vlan(\d+)", interface, re.IGNORECASE)
        vlan = vlan_match.group(1) if vlan_match else None

        results.append({
            "ip": ip,
            "mac": mac,
            "vlan": vlan
        })
        
        
    mac_to_interface = {}
    pattern = re.compile(
        r"[+*]\s+\d+\s+([\da-f\.]+)\s+\S+\s+\d+\s+\S+\s+\S+\s+(\S+)",
        re.IGNORECASE
    )

    for match in pattern.finditer(mac_text):
        mac = match.group(1).lower()
        interface = match.group(2)
        mac_to_interface[mac] = interface

    for entry in results:
        mac = entry["mac"]
        if mac in mac_to_interface:
            entry["interface"] = mac_to_interface[mac]

    return results
```

```python [hp_comware.py]
def parse_h3c_arp(arp_text: str) -> List[Dict[str, str]]:
    """
    从 H3C 交换机 ARP 输出中提取 IP、MAC、VLAN、Interface 字段。

    :param arp_text: H3C ARP 原始文本
    :return: 包含提取字段的字典列表
    """
    pattern = re.compile(
        r"(?P<ip>\d+\.\d+\.\d+\.\d+)\s+"
        r"(?P<mac>(?:[0-9a-f]{4}-){2}[0-9a-f]{4})\s+"
        r"(?P<vlan>\S+)\s+"
        r"(?P<interface>\S+)",
        re.IGNORECASE
    )

    results = []
    for match in pattern.finditer(arp_text):
        results.append({
            'ip': match.group("ip"),
            'mac': match.group("mac"),
            'vlan': match.group("vlan"),
            'interface': match.group("interface"),
        })
    return results
```

```python [huawei_arp.py]
def parse_huawei_arp(arp_text: str) -> List[Dict[str, str]]:
    lines = arp_text.strip().splitlines()
    entries = []
    i = 0

    while i < len(lines):
        line = lines[i].strip()

        # ✅ 类型1：完整一行，动态，有 vlan
        match = re.match(
            r'^(\d+\.\d+\.\d+\.\d+)\s+'
            r'([0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4})\s+'
            r'\d+\s+D/(\d+)\s+'
            r'(\S+)',
            line)
        if match:
            ip, mac, vlan, interface = match.groups()
            entries.append({
                'ip': ip,
                'mac': mac,
                'interface': interface,
                'vlan': vlan
            })
            i += 1
            continue

        # ✅ 类型2：完整一行，静态（无 VLAN）
        match = re.match(
            r'^(\d+\.\d+\.\d+\.\d+)\s+'
            r'([0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4})\s+'
            r'I\s+'
            r'(\S+)',
            line)
        if match:
            ip, mac, interface = match.groups()
            entries.append({
                'ip': ip,
                'mac': mac,
                'interface': interface,
                'vlan': None
            })
            i += 1
            continue

        # ✅ 类型3：分行样式（动态，占两行）
        match = re.match(
            r'^(\d+\.\d+\.\d+\.\d+)\s+'
            r'([0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4})\s+\d*\s+\S+\s+(\S+)',
            line)
        if match:
            ip, mac, interface = match.groups()
            vlan = None
            # 尝试读取下一行中的 vlan
            if i + 1 < len(lines):
                next_line = lines[i + 1].strip()
                vlan_match = re.match(r'^(\d+)', next_line)
                if vlan_match:
                    vlan = vlan_match.group(1)
                    i += 1  # 跳过 vlan 行
            entries.append({
                'ip': ip,
                'mac': mac,
                'interface': interface,
                'vlan': vlan
            })

        i += 1

    return entries
```
:::

## 常见问题
我这里列举一下我之前遇到的问题，当然由于开发已经有近两年，太久的问题已经想不起来了QAQ，如果您有问题欢迎下方提问。

### H3C在netmiko中该使用什么型号？
该[链接](https://github.com/ktbyers/netmiko/blob/master/netmiko/ssh_dispatcher.py)给出了官方支持列表**CLASS_MAPPER_BASE**，此列表中找不到任何H3C，查询测试发现应该使用 **hp_comware**

### 华为AC交换机配置过长
通过配置 *send_command* 函数中的 *read_timeout* 参数解决。
```python
# 我的项目中使用如下行解决AC交换机配置超过几万行的问题
read_timeout = 40 if "AC6605" not in device.name else 300
```

### 