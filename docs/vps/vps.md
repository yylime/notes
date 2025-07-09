# VPS(小秘书)
2025-02-11购入小秘书[San Jose](https://vps.hosting/cart/san-jose-cloud-kvm-vps/)
## 价格
| 型号                     | 价格                             | 核心 | 内存 | 硬盘  | 流量         | 带宽 |
|------------------------|--------------------------------|----|----|-----|------------|----|
| San Jose | 89.95 EUR/年 -> 63.10/月，¥757/年 | 2  | 1G  | 20G | 1T(in+out) | 1G |


## San Jose
线路顶级，延迟顶级
### 硬件
[测评脚本](https://github.com/masonr/yet-another-bench-script)，可惜配置低都跑不了Geekbench。
```shell:no-line-numbers
Wed Jul  9 02:20:36 AM UTC 2025

Basic System Information:
---------------------------------
Uptime     : 28 days, 1 hours, 2 minutes
Processor  : Intel(R) Xeon(R) Platinum 8163 CPU @ 2.50GHz
CPU cores  : 2 @ 2494.140 MHz
AES-NI     : ✔ Enabled
VM-x/AMD-V : ✔ Enabled
RAM        : 961.2 MiB
Swap       : 256.0 MiB
Disk       : 19.6 GiB
Distro     : Ubuntu 24.04.2 LTS
Kernel     : 6.8.0-60-generic
VM Type    : KVM
IPv4/IPv6  : ✔ Online / ❌ Offline

IPv4 Network Information:
---------------------------------
ISP        : xTom
ASN        : AS6233 xTom
Host       : xTom
Location   : San Jose, California (CA)
Country    : United States

fio Disk Speed Tests (Mixed R/W 50/50) (Partition /dev/vda1):
---------------------------------
Block Size | 4k            (IOPS) | 64k           (IOPS)
  ------   | ---            ----  | ----           ----
Read       | 52.72 MB/s   (13.1k) | 954.65 MB/s  (14.9k)
Write      | 52.80 MB/s   (13.2k) | 959.67 MB/s  (14.9k)
Total      | 105.52 MB/s  (26.3k) | 1.91 GB/s    (29.9k)
           |                      |
Block Size | 512k          (IOPS) | 1m            (IOPS)
  ------   | ---            ----  | ----           ----
Read       | 1.23 GB/s     (2.4k) | 1.22 GB/s     (1.1k)
Write      | 1.30 GB/s     (2.5k) | 1.30 GB/s     (1.2k)
Total      | 2.53 GB/s     (4.9k) | 2.53 GB/s     (2.4k)

Geekbench 0!
```
### IP质量
三网回程没什么好说的，电信：CN2/CN2、移动：CMIN2/CMIN2、联通：9929/9929
![IP质量](https://Report.Check.Place/ip/J4IAUGEY0.svg)

### 测速
iperf3，北京电信带宽200M单线程测试
```shell:no-line-numbers
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.01   sec   768 KBytes  6.25 Mbits/sec
[  5]   1.01-2.01   sec  12.0 MBytes   101 Mbits/sec
[  5]   2.01-3.01   sec  13.6 MBytes   114 Mbits/sec
[  5]   3.01-4.01   sec  23.4 MBytes   196 Mbits/sec
[  5]   4.01-5.00   sec  11.2 MBytes  94.5 Mbits/sec
[  5]   5.00-6.01   sec  20.2 MBytes   170 Mbits/sec
[  5]   6.01-7.00   sec  15.4 MBytes   130 Mbits/sec
[  5]   7.00-8.00   sec  17.8 MBytes   148 Mbits/sec
[  5]   8.00-9.01   sec  15.9 MBytes   133 Mbits/sec
[  5]   9.01-10.01  sec  18.4 MBytes   153 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.17  sec   159 MBytes   132 Mbits/sec  1115            sender
[  5]   0.00-10.01  sec   149 MBytes   125 Mbits/sec                  receiver
```
多线程
```shell:no-line-numbers
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.16  sec  73.8 MBytes  60.9 Mbits/sec  3722            sender
[  5]   0.00-10.01  sec  71.5 MBytes  59.9 Mbits/sec                  receiver
[  7]   0.00-10.16  sec  91.6 MBytes  75.6 Mbits/sec  3537            sender
[  7]   0.00-10.01  sec  77.6 MBytes  65.1 Mbits/sec                  receiver
[  9]   0.00-10.16  sec   104 MBytes  85.7 Mbits/sec  4548            sender
[  9]   0.00-10.01  sec  93.9 MBytes  78.7 Mbits/sec                  receiver
[ 11]   0.00-10.16  sec   107 MBytes  88.1 Mbits/sec  4413            sender
[ 11]   0.00-10.01  sec  97.1 MBytes  81.4 Mbits/sec                  receiver
[ 13]   0.00-10.16  sec  71.2 MBytes  58.8 Mbits/sec  2768            sender
[ 13]   0.00-10.01  sec  66.6 MBytes  55.9 Mbits/sec                  receiver
[SUM]   0.00-10.16  sec   447 MBytes   369 Mbits/sec  18988             sender
[SUM]   0.00-10.01  sec   407 MBytes   341 Mbits/sec                  receiver
```