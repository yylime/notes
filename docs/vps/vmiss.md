# VPS(小秘书)
2025-04-10购入VMISS[CN.HK.BGP.V2.Basic](https://app.vmiss.com/aff.php?aff=2919)
## 价格
| 型号                     | 价格                             | 核心 | 内存 | 硬盘  | 流量         | 带宽 |
|------------------------|--------------------------------|----|----|-----|------------|----|
| CN.HK.BGP.V2.Basic | 5 CAD/月 -> ¥26.26/月，¥315.06/年 | 1  | 1G  | 10G | 400G(in+out) | 100M |


## CN.HK.BGP.V2.Basic
延迟很低，几乎不会绕路，三网CMI，并且商家常年有折扣，年付折扣叠加很不错，工单及时，性价比很好！
### 硬件
[测评脚本](https://github.com/masonr/yet-another-bench-script)，性能一般，但是做frp穿透挂个探针没啥大问题。
```shell:no-line-numbers
Thu Jul 10 01:55:43 AM EDT 2025

Basic System Information:
---------------------------------
Uptime     : 122 days, 3 hours, 44 minutes
Processor  : Intel Core Processor (Broadwell, IBRS)
CPU cores  : 1 @ 2599.996 MHz
AES-NI     : ✔ Enabled
VM-x/AMD-V : ✔ Enabled
RAM        : 973.3 MiB
Swap       : 1024.0 MiB
Disk       : 9.8 GiB
Distro     : Debian GNU/Linux 12 (bookworm)
Kernel     : 6.1.0-22-cloud-amd64
VM Type    : KVM
IPv4/IPv6  : ✔ Online / ❌ Offline

IPv4 Network Information:
---------------------------------
ISP        : VMISS Inc.
ASN        : AS967 VMISS Inc.
Host       : VMISS Inc
Location   : Hong Kong, Kowloon ()
Country    : Hong Kong

fio Disk Speed Tests (Mixed R/W 50/50) (Partition /dev/vda1):
---------------------------------
Block Size | 4k            (IOPS) | 64k           (IOPS)
  ------   | ---            ----  | ----           ----
Read       | 116.06 MB/s  (29.0k) | 1.20 GB/s    (18.7k)
Write      | 116.37 MB/s  (29.0k) | 1.20 GB/s    (18.8k)
Total      | 232.43 MB/s  (58.1k) | 2.41 GB/s    (37.6k)
           |                      |
Block Size | 512k          (IOPS) | 1m            (IOPS)
  ------   | ---            ----  | ----           ----
Read       | 835.19 MB/s   (1.6k) | 1.37 GB/s     (1.3k)
Write      | 879.56 MB/s   (1.7k) | 1.46 GB/s     (1.4k)
Total      | 1.71 GB/s     (3.3k) | 2.83 GB/s     (2.7k)
```
### IP质量
三网回程 CMIN2/CMIN2
![IP质量](https://Report.Check.Place/ip/3VZSSBNAR.svg)

### 测速
iperf3，北京电信带宽200M单线程测试。接口是100M限速，单线程基本可以跑满，多线程则可以到400M+，唯一的缺点基础只有400G流量。
```shell:no-line-numbers
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  10.6 MBytes  88.8 Mbits/sec
[  5]   1.00-2.00   sec  13.4 MBytes   112 Mbits/sec
[  5]   2.00-3.00   sec  13.1 MBytes   110 Mbits/sec
[  5]   3.00-4.01   sec  17.0 MBytes   142 Mbits/sec
[  5]   4.01-5.01   sec  18.0 MBytes   151 Mbits/sec
[  5]   5.01-6.01   sec  15.8 MBytes   132 Mbits/sec
[  5]   6.01-7.00   sec  16.6 MBytes   140 Mbits/sec
[  5]   7.00-8.01   sec  14.6 MBytes   122 Mbits/sec
[  5]   8.01-9.00   sec  18.0 MBytes   152 Mbits/sec
[  5]   9.00-10.00  sec  15.0 MBytes   126 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.05  sec   156 MBytes   130 Mbits/sec  6911            sender
[  5]   0.00-10.00  sec   152 MBytes   128 Mbits/sec                  receiver
```
多线程
```shell:no-line-numbers
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.05  sec   123 MBytes   102 Mbits/sec  11765            sender
[  5]   0.00-10.00  sec   119 MBytes  99.8 Mbits/sec                  receiver
[  7]   0.00-10.05  sec   126 MBytes   105 Mbits/sec  12220            sender
[  7]   0.00-10.00  sec   122 MBytes   102 Mbits/sec                  receiver
[  9]   0.00-10.05  sec   115 MBytes  96.3 Mbits/sec  9259            sender
[  9]   0.00-10.00  sec   113 MBytes  94.6 Mbits/sec                  receiver
[ 11]   0.00-10.05  sec  51.9 MBytes  43.3 Mbits/sec  4950            sender
[ 11]   0.00-10.00  sec  49.0 MBytes  41.1 Mbits/sec                  receiver
[ 13]   0.00-10.05  sec   108 MBytes  89.8 Mbits/sec  7742            sender
[ 13]   0.00-10.00  sec   104 MBytes  87.1 Mbits/sec                  receiver
[SUM]   0.00-10.05  sec   523 MBytes   436 Mbits/sec  45936             sender
[SUM]   0.00-10.00  sec   506 MBytes   425 Mbits/sec                  receiver
```