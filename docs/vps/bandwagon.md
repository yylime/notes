# Bandwagon(搬瓦工)
2025-07-08购入之前的套餐[NODESEEK-BIGGERBOX-PRO](https://vps.bigdata.icu/hQoPn)，购买后升级为NODESEEK-MEGABOX-PRO。49usd/年，优惠后46usd/年。
## 价格
| 型号                     | 价格                             | 核心 | 内存 | 硬盘  | 流量         | 带宽 |
|------------------------|--------------------------------|----|----|-----|------------|----|
| NODESEEK-BIGGERBOX-PRO | 39 USD/年 -> ¥23.34/月，¥280.07/年 | 1  | 1  | 20G | 1T(in+out) | 3G |
| NODESEEK-MEGABOX-PRO   | 49 USD/年 -> ¥31.07/月，¥368.07/年 | 2  | 2  | 40G | 1T(in+out) | 3G |

## NODESEEK-MEGABOX-PRO
应该是性价比最高的瓦工产品了，新机房DC6。
### 硬件
[测评脚本](https://github.com/masonr/yet-another-bench-script)
```shell:no-line-numbers
Wed Jul  9 01:41:34 UTC 2025

Basic System Information:
---------------------------------
Uptime     : 0 days, 16 hours, 39 minutes
Processor  : AMD EPYC-Genoa Processor
CPU cores  : 2 @ 2794.748 MHz
AES-NI     : ✔ Enabled
VM-x/AMD-V : ❌ Disabled
RAM        : 2.0 GiB
Swap       : 545.0 MiB
Disk       : 40.2 GiB
Distro     : Ubuntu 24.04 LTS
Kernel     : 6.8.0-31-generic
VM Type    : KVM
IPv4/IPv6  : ✔ Online / ❌ Offline

IPv4 Network Information:
---------------------------------
ISP        : IT7 Networks Inc
ASN        : AS25820 IT7 Networks Inc
Host       : IT7 Networks Inc
Location   : Los Angeles, California (CA)
Country    : United States

fio Disk Speed Tests (Mixed R/W 50/50) (Partition /dev/sda3):
---------------------------------
Block Size | 4k            (IOPS) | 64k           (IOPS)
  ------   | ---            ----  | ----           ----
Read       | 163.71 MB/s  (40.9k) | 722.75 MB/s  (11.2k)
Write      | 164.14 MB/s  (41.0k) | 726.55 MB/s  (11.3k)
Total      | 327.85 MB/s  (81.9k) | 1.44 GB/s    (22.6k)
           |                      |
Block Size | 512k          (IOPS) | 1m            (IOPS)
  ------   | ---            ----  | ----           ----
Read       | 1.01 GB/s     (1.9k) | 1.34 GB/s     (1.3k)
Write      | 1.06 GB/s     (2.0k) | 1.43 GB/s     (1.4k)
Total      | 2.07 GB/s     (4.0k) | 2.78 GB/s     (2.7k)

Geekbench 6 Benchmark Test:
---------------------------------
Test            | Value
                |
Single Core     | 1128
Multi Core      | 2029
Full Test       | https://browser.geekbench.com/v6/cpu/12779978
```
### IP质量
三网回程没什么好说的，电信：CN2/CN2、移动：CMIN2/CMIN2、联通：9929/CN2
质量不咋地只能说能用.
![IP质量](https://Report.Check.Place/ip/15XV27ZOF.svg)

### 测速
iperf3，北京电信带宽200M单线程测试
```shell:no-line-numbers
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec   768 KBytes  6.27 Mbits/sec
[  5]   1.00-2.01   sec  12.0 MBytes   101 Mbits/sec
[  5]   2.01-3.01   sec  11.8 MBytes  98.5 Mbits/sec
[  5]   3.01-4.01   sec  16.5 MBytes   138 Mbits/sec
[  5]   4.01-5.01   sec  13.4 MBytes   113 Mbits/sec
[  5]   5.01-6.00   sec  15.9 MBytes   133 Mbits/sec
[  5]   6.00-7.00   sec  13.9 MBytes   117 Mbits/sec
[  5]   7.00-8.01   sec  11.9 MBytes  99.2 Mbits/sec
[  5]   8.01-9.01   sec  16.4 MBytes   137 Mbits/sec
[  5]   9.01-10.01  sec  16.1 MBytes   135 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.16  sec   131 MBytes   108 Mbits/sec  1045            sender
[  5]   0.00-10.01  sec   128 MBytes   108 Mbits/sec                  receiver
```
多线程
```sh:no-line-numbers
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.16  sec  96.4 MBytes  79.6 Mbits/sec  2201            sender
[  5]   0.00-10.01  sec  92.6 MBytes  77.7 Mbits/sec                  receiver
[  7]   0.00-10.16  sec  90.1 MBytes  74.4 Mbits/sec  2003            sender
[  7]   0.00-10.01  sec  86.0 MBytes  72.1 Mbits/sec                  receiver
[  9]   0.00-10.16  sec  85.0 MBytes  70.2 Mbits/sec  1626            sender
[  9]   0.00-10.01  sec  81.6 MBytes  68.4 Mbits/sec                  receiver
[ 11]   0.00-10.16  sec  82.4 MBytes  68.0 Mbits/sec  1841            sender
[ 11]   0.00-10.01  sec  78.5 MBytes  65.8 Mbits/sec                  receiver
[ 13]   0.00-10.16  sec  97.6 MBytes  80.6 Mbits/sec  2726            sender
[ 13]   0.00-10.01  sec  94.9 MBytes  79.5 Mbits/sec                  receiver
[SUM]   0.00-10.16  sec   452 MBytes   373 Mbits/sec  10397             sender
[SUM]   0.00-10.01  sec   434 MBytes   364 Mbits/sec                  receiver
```