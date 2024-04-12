# 启动xv6并调试

## 环境配置

以下步骤均以window（10或11）为标准，其它操作系统（如macOS、Ubuntu等）参考[2021年6.S081的tools](https://pdos.csail.mit.edu/6.S081/2021/tools.html)

### 安装WSL2并添加子系统Ubuntu20.04

可以参考该视频链接[link1](https://www.bilibili.com/video/BV1mX4y177dJ/)

- 切换到桌面，键入`win+s`，进入搜索栏，输入`功能`二字，找到适用于**Linux的Windows子系统**和**虚拟平台**将它们两个勾选，如图所示：

- 切换到桌面，键入`win+s`，进入搜索栏，输入`cmd`，**分别**输入如下指令，安装WSL2

```bash
# 安装最新版wsl
wsl --update
# 使用wsl2
wsl --set-default-version 2
```

- 在上一步的基础上，输入如下指令，安装子系统**Ubuntu20.04**

```bash
# 安装子系统Ubuntu20.04
wsl.exe --install Ubuntu-20.04
```

- 在子系统**Ubuntu20.04**中，输入用户名和密码，注册用户即可

### 安装相关软件

**警告：接下来的操作请确保已经在Ubuntu-20.04子系统的终端页面中**

在**Ubuntu-20.04**子系统的终端页面中，**分别**输入如下指令：

```bash
$ sudo apt-get update && sudo apt-get upgrade
$ sudo apt-get install git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
```

- `sudo`是特权用户指令的意思，使用特权用户指令会用到之前注册时的密码

- `$`和其之后的空格不用输入，可以理解为**分别**输入如下指令：

  ```
  sudo apt-get update && sudo apt-get upgrade
  sudo apt-get install git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
  ```

  - 之所以标识`$`和其之后的空格是为了**表明我们在终端进行输入**，之后不再重复这点

### 在window中安装Git

请自行查找如何在window中安装Git，当**Ubuntu-20.04子系统**因为网络问题无法访问Git相关链接，可以在window中进行相关Git操作

### 安装并启动xv6

**警告：接下来的操作请确保已经在Ubuntu-20.04子系统的终端页面中**

第一步，克隆xv6

```bash
$ git clone https://github.com/duilec/xv6-2021-labs.git
Cloning into 'xv6-labs-2021'...
...
$ cd xv6-labs-2021
```

第二步，暂存当前分支，并切换分支到`util`

```bash
$ git stash
$ git checkout util
```

第三步，构建并运行`xv6`

```bash
$ make qemu
```

会有如下结果

```bash
riscv64-unknown-elf-gcc    -c -o kernel/entry.o kernel/entry.S
riscv64-unknown-elf-gcc -Wall -Werror -O -fno-omit-frame-pointer -ggdb -DSOL_UTIL -MD -mcmodel=medany -ffreestanding -fno-common -nostdlib -mno-relax -I. -fno-stack-protector -fno-pie -no-pie   -c -o kernel/start.o kernel/start.c
...  
balloc: first 591 blocks have been allocated
balloc: write bitmap block at sector 45
qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel -m 128M -smp 3 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0

xv6 kernel is booting

hart 2 starting
hart 1 starting
init: starting sh
$ 
```

第四步，简单地进行测试，输入指令`ls`

```bash
$ ls
```

会有如下结果

```bash
.              1 1 1024
..             1 1 1024
README         2 2 2059
xargstest.sh   2 3 93
cat            2 4 24256
echo           2 5 23080
forktest       2 6 13272
grep           2 7 27560
init           2 8 23816
kill           2 9 23024
ln             2 10 22880
ls             2 11 26448
mkdir          2 12 23176
rm             2 13 23160
sh             2 14 41976
stressfs       2 15 24016
usertests      2 16 148456
grind          2 17 38144
wc             2 18 25344
zombie         2 19 22408
console        3 20 0
```



### 退出xv6，回到终端

在xv6中，**先同时按`ctrl+a`，然后松开，最后只按`x`**，即可退出xv6

### 可能遇到的问题

#### 安装相关软件时的网络问题

- 原因：下载时需要连接到国外网站
- 解决方案：使用清华源

### 最新版本

可以使用MIT[最新课程](https://pdos.csail.mit.edu/6.S081/2023/schedule.html)的版本，实验内容有部分差异link0

## 调试和编程的平台

### 调试平台

软件要求：在windos中安装VSCode（必须），在**Ubuntu-20.04**子系统中安装Vim（视个人需要）

建议使用print函数（即调用C语言库的print函数，在特定的地方打印日志）或者GDB调试

- 如何使用GDB调试？
  过程中需要打开两个终端，一个用来启动qemu，一个用来正常debug（调试）
  建议debug时，启动qemu只用一个cpu
  
  第一步，在一个终端中输入
  
  ```bash
  $ make CPUS=1 qemu-gdb
  ```
  
  会显示如下内容：
  
  ```bash
  *** Now run 'gdb' in another window.
  qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel -m 128M -smp 1 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 -S -gdb tcp::26000
  ```
  
  第二步，在另一个终端中输入
  
  ```bash
  $ gdb-multiarch kernel/kernel
  ```
  
  会显示如下内容，从而在这个终端进行调试
  
  ```bash
  GNU gdb (Ubuntu 9.2-0ubuntu1~20.04.1) 9.2
  Copyright (C) 2020 Free Software Foundation, Inc.
  License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
  This is free software: you are free to change and redistribute it.
  There is NO WARRANTY, to the extent permitted by law.
  Type "show copying" and "show warranty" for details.
  This GDB was configured as "x86_64-linux-gnu".
  Type "show configuration" for configuration details.
  For bug reporting instructions, please see:
  <http://www.gnu.org/software/gdb/bugs/>.
  Find the GDB manual and other documentation resources online at:
      <http://www.gnu.org/software/gdb/documentation/>.
  
  For help, type "help".
  Type "apropos word" to search for commands related to "word"...
  Reading symbols from kernel/kernel...
  The target architecture is assumed to be riscv:rv64
  0x0000000000001000 in ?? ()
  (gdb)
  ```

进入GDB终端调试页面后如何进行调试，可以参考[link2](https://www.bilibili.com/video/BV1DY4y1a7YD/?spm_id_from=333.788&vd_source=167c726c8eff4e6707afa7867f993bb4)中文视频、[link3](https://www.bilibili.com/video/BV19k4y1C7kA?p=2&vd_source=167c726c8eff4e6707afa7867f993bb4)英文视频（这个主要看最后一部分）

也可以使用VSCode图形化GDB调试，参考[link4](https://hitsz-cslab.gitee.io/os-labs/remote_env_gdb/)、[link5](https://hitsz-cslab.gitee.io/os-labs/remote_env_gdb2/)

### 编程平台

建议在终端安装Vim进行编程，或者链接到VSCode编程平台进行编程

- 如何链接到VSCode编程平台？
  第一步，在VSCode安装插件Remote - WSL
  第二步，在**Ubuntu-20.04**子系统的终端页面中，进入项目页面，即是输入指令

  ```bash
  $ cd xv6-labs-2021
  ```

  第三步，链接到VSCode编程平台，即是输入指令

  ```bash
  $ code .
  ```

## 参考

[Fall 2021: 6.S081](https://pdos.csail.mit.edu/6.S081/2021/)

[WSL官网](https://learn.microsoft.com/zh-cn/windows/wsl/)

[Ubuntu官网](https://cn.ubuntu.com/)

[安装WSL2并添加子系统Ubuntu20.04视频链接](https://www.bilibili.com/video/BV1mX4y177dJ/)

