# 使用rust连接交换机

## 1. 问题描述
最近尝试使用rust来连接交换机进行巡检，发现H3C等交换机存在密钥交换失败的问题，但是我在另外一台Centos没有任何问题，具体报错如下：
```
   Compiling libz-sys v1.1.22
   Compiling openssl-sys v0.9.107
   Compiling mysqlclient-sys v0.4.5
   Compiling libssh2-sys v0.3.1
   Compiling diesel v2.2.9
   Compiling ssh2 v0.9.5
   Compiling switch_ssh v0.1.0 (/home/yiyulin/repos/switch_ssh)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 15.15s
     Running `target/debug/switch_ssh`

thread 'main' panicked at src/main.rs:15:22:
called `Result::unwrap()` on an `Err` value: Error { code: Session(-8), msg: "Unable to exchange encryption keys" }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

## 2. 问题分析
由于之前在官方的Github中我提交过issue，在新版本后使用了新的libssh2版本，并且我在Centos测试可以连接到不同厂商的交换机（思科、华为
华三）都没问题，但是在Ubuntu上使用libssh2-sys的0.3.1版本连接H3C交换机时确有问题。所以决定手动编译libssh2的最新版本，查看是否可以解决问题。

## 3. 问题解决
使用cmake，因为他会自动创建pkg-config文件，rust可以配置环境变量来使用libssh2-sys依赖，所以直接使用cmake编译libssh2即可。由于初学rust，之前在这里卡了很久，最近GPT帮我解决了这个问题。（之前也问过，但是没有给出好的方案
### 3.1 编译libssh2
```bash
git clone https://github.com/libssh2/libssh2.git
cd libssh2
mkdir build
cd build
cmake ..
sudo make install
```

### 3.2 配置环境变量
`.cargo/config.toml`文件中添加如下内容
```toml
LIBSSH2_SYS_USE_PKG_CONFIG = "1"
PKG_CONFIG_PATH = "/usr/local/lib/pkgconfig"
```
然后执行
```bash
cargo clean
cargo build
```

### 3.3 测试
```rust showLineNumbers
    let tcp = TcpStream::connect("172.20.0.1:22").unwrap();
    let mut sess = Session::new().unwrap();
    sess.set_tcp_stream(tcp);
    sess.handshake().unwrap();

    sess.userauth_password("yiyulin", "*****").unwrap();
    assert!(sess.authenticated());

    let mut channel = sess.channel_session().unwrap();

    channel.exec("dis version").unwrap();
    let mut s = String::new();
    channel.read_to_string(&mut s).unwrap();
    println!("{}", s);
    channel.wait_close().unwrap();
    println!("{}", channel.exit_status().unwrap());
```
输出正常
```
H3C Comware Software, Version 7.1.070, Release 6615P05
Copyright (c) 2004-2022 New H3C Technologies Co., Ltd. All rights reserved.
H3C S5560X-54C-EI uptime is 47 weeks, 0 days, 5 hours, 34 minutes
Last reboot reason : Cold reboot

Boot image: flash:/s5560x_ei-cmw710-boot-r6615p05.bin
Boot image version: 7.1.070, Release 6615P05
  Compiled Feb 08 2022 11:00:00
System image: flash:/s5560x_ei-cmw710-system-r6615p05.bin
System image version: 7.1.070, Release 6615P05
  Compiled Feb 08 2022 11:00:00
Feature image(s) list:
  flash:/s5560x_ei-cmw710-freeradius-r6615p05.bin, version: 7.1.070, Release 6615P05
    Compiled Feb 08 2022 11:00:00
  flash:/s5560x-ei-cmw710-escan-r6615p05.bin, version: 7.1.070, Release 6615P05
    Compiled Feb 08 2022 11:00:00


Slot 1:
Uptime is 47 weeks,0 days,5 hours,34 minutes
S5560X-54C-EI with 2 Processors
BOARD TYPE:         S5560X-54C-EI
DRAM:               2048M bytes
FLASH:              512M bytes
PCB 1 Version:      VER.B
Bootrom Version:    119
CPLD 1 Version:     002
Release Version:    H3C S5560X-54C-EI-6615P05
Patch Version  :    None
Reboot Cause  :     ColdReboot
[SubSlot 0] 48GE+4SFP Plus
```
