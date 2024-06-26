#  Lab1：工具程序

##  实验任务

切换到util分支

```bash
$ cd xv6-labs-2021
$ git checkout util
Branch 'util' set up to track remote branch 'util' from 'origin'.
Switched to a new branch 'util'
```

如何获取xv6源代码参考lab0

### uptime

难度：简单

工具程序`uptime`的功能是显示Xv6启动之后的计时数。一个滴答(tick)是由xv6内核定义的时间概念，即来自定时器芯片的两个中断之间的时间。您的解决方案应该在文件*user/uptime.c*中。

**提示：**

- 在你开始编码之前，请阅读《book-riscv-rev1》的第一章
- 看看其他的一些程序（如*/user/echo.c, /user/grep.c, /user/rm.c*）查看如何获取传递给程序的命令行参数
- 使用系统调用`uptime`
- 请参阅*kernel/sysproc.c*以实现`uptime`系统调用的xv6内核代码，*user/user.h*提供了`uptime`的声明以便其他程序调用，用汇编程序编写的*user/usys.S*可以帮助`uptime`从用户区跳转到内核区。
- 确保`main`函数调用`exit()`以退出程序。
- 将你的`uptime`程序添加到*Makefile*中的`UPROGS`中；完成之后，`make qemu`将编译您的程序，并且您可以从xv6的shell运行它。
- 看看Kernighan和Ritchie编著的《C程序设计语言》（第二版）来了解C语言。

从xv6 shell运行程序：

```bash
$ make qemu
...
init: starting sh
$ uptime
21 ticks in xv6
```

ticks的数值是任意的，如果不同，解决方案也是正确的。运行`make grade`看看你是否真的通过了测试。

请注意，`make grade`运行所有测试，包括下面作业的测试。如果要对一项作业运行成绩测试，请键入（不要启动XV6，在外部终端下使用）：

```bash
$ ./grade-lab-util uptime
```

这将运行与`sleep`匹配的成绩测试。或者，您可以键入：

```bash
$ make GRADEFLAGS=uptime grade
```

效果是一样的。

### sleep

难度：简单

实现xv6的UNIX程序`sleep`：您的`sleep`应该暂停到用户指定的计时数。一个滴答(tick)是由xv6内核定义的时间概念，即来自定时器芯片的两个中断之间的时间。您的解决方案应该在文件*user/sleep.c*中

**提示：**

- 在你开始编码之前，请阅读《book-riscv-rev1》的第一章
- 看看其他的一些程序（如*/user/echo.c, /user/grep.c, /user/rm.c*）查看如何获取传递给程序的命令行参数
- 如果用户忘记传递参数，`sleep`应该打印一条错误信息
- 命令行参数作为字符串传递; 您可以使用`atoi`将其转换为数字（详见*user/ulib.c*）
- 使用系统调用`sleep`
- 请参阅*kernel/sysproc.c*以获取实现`sleep`系统调用的xv6内核代码（查找`sys_sleep`），*user/user.h*提供了`sleep`的声明以便其他程序调用，用汇编程序编写的*user/usys.S*可以帮助`sleep`从用户区跳转到内核区。
- 确保`main`函数调用`exit()`以退出程序。
- 将你的`sleep`程序添加到*Makefile*中的`UPROGS`中；完成之后，`make qemu`将编译您的程序，并且您可以从xv6的shell运行它。
- 看看Kernighan和Ritchie编著的《C程序设计语言》（第二版）来了解C语言。

从xv6 shell运行程序：

```bash
$ make qemu
...
init: starting sh
$ sleep 10
(nothing happens for a little while)
$
```

如果程序在如上所示运行时暂停，则解决方案是正确的。运行`make grade`看看你是否真的通过了睡眠测试。

请注意，`make grade`运行所有测试，包括下面作业的测试。如果要对一项作业运行成绩测试，请键入（不要启动XV6，在外部终端下使用）：

```bash
$ ./grade-lab-util sleep
```

这将运行与`sleep`匹配的成绩测试。或者，您可以键入：

```bash
$ make GRADEFLAGS=sleep grade
```

效果是一样的。

### pingpong

难度：简单

编写一个使用UNIX系统调用的程序来在两个进程之间“ping-pong”一个字节，请使用两个管道，每个方向一个。父进程应该向子进程发送一个字节;子进程应该打印“`<pid>: received ping`”，其中`<pid>`是进程ID，并在管道中写入字节发送给父进程，然后退出;父级应该从读取从子进程而来的字节，打印“`<pid>: received pong`”，然后退出。您的解决方案应该在文件*user/pingpong.c*中。

**提示：**

- 使用`pipe`来创造管道
- 使用`fork`创建子进程
- 使用`read`从管道中读取数据，并且使用`write`向管道中写入数据
- 使用`getpid`获取调用进程的pid
- 将程序加入到*Makefile*的`UPROGS`
- xv6上的用户程序有一组有限的可用库函数。您可以在*user/user.h*中看到可调用的程序列表；源代码（系统调用除外）位于*user/ulib.c*、*user/printf.c*和*user/umalloc.c*中。

运行程序应得到下面的输出

```bash
$ make qemu
...
init: starting sh
$ pingpong
4: received ping
3: received pong
$
```

如果您的程序在两个进程之间交换一个字节并产生如上所示的输出，那么您的解决方案是正确的。

### Primes

难度：困难

使用管道编写prime sieve(筛选素数)的并发版本。这个想法是由Unix管道的发明者Doug McIlroy提出的。请查看[这个网站](http://swtch.com/~rsc/thread/)(翻译在下面)，该网页中间的图片和周围的文字解释了如何做到这一点。您的解决方案应该在*user/primes.c*文件中。

您的目标是使用`pipe`和`fork`来设置管道。第一个进程将数字2到35输入管道。对于每个素数，您将安排创建一个进程，该进程通过一个管道从其左邻居读取数据，并通过另一个管道向其右邻居写入数据。由于xv6的文件描述符和进程数量有限，因此第一个进程可以在35处停止。

**提示：**

- 请仔细关闭进程不需要的文件描述符，否则您的程序将在第一个进程达到35之前就会导致xv6系统资源不足。
- 一旦第一个进程达到35，它应该使用`wait`等待整个管道终止，包括所有子孙进程等等。因此，主`primes`进程应该只在打印完所有输出之后，并且在所有其他`primes`进程退出之后退出。
- 提示：当管道的`write`端关闭时，`read`返回零。
- 最简单的方法是直接将32位（4字节）int写入管道，而不是使用格式化的ASCII I/O。
- 您应该仅在需要时在管线中创建进程。
- 将程序添加到*Makefile*中的`UPROGS`

如果您的解决方案实现了基于管道的筛选并产生以下输出，则是正确的：

```bash
$ make qemu
...
init: starting sh
$ primes
prime 2
prime 3
prime 5
prime 7
prime 11
prime 13
prime 17
prime 19
prime 23
prime 29
prime 31
$
```

### find

难度：中等

写一个简化版本的UNIX的`find`程序：查找目录树中具有特定名称的所有文件，你的解决方案应该放在*user/find.c*

提示：

- 查看*user/ls.c*文件学习如何读取目录
- 使用递归允许`find`下降到子目录中
- 不要在“`.`”和“`..`”目录中递归
- 对文件系统的更改会在qemu的运行过程中一直保持；要获得一个干净的文件系统，请运行`make clean`，然后`make qemu`
- 你将会使用到C语言的字符串，要学习它请看《C程序设计语言》（K&R）,例如第5.5节
- 注意在C语言中不能像python一样使用“`==`”对字符串进行比较，而应当使用`strcmp()`
- 将程序加入到*Makefile*的`UPROGS`

如果你的程序输出下面的内容，那么它是正确的（当文件系统中包含文件***b\***和***a/b\***的时候）

```bash
$ make qemu
...
init: starting sh
$ echo > b
$ mkdir a
$ echo > a/b
$ find . b
./b
./a/b
$
```

### xargs

难度：中等

编写一个简化版UNIX的`xargs`程序：它从标准输入中按行读取，并且为每一行执行一个命令，将行作为参数提供给命令。你的解决方案应该在*user/xargs.c*

下面的例子解释了`xargs`的行为

```bash
$ echo hello too | xargs echo bye
bye hello too
$
```

注意，这里的命令是`echo bye`，额外的参数是`hello too`，这样就组成了命令`echo bye hello too`，此命令输出`bye hello too`

请注意，UNIX上的`xargs`进行了优化，一次可以向该命令提供更多的参数。 我们不需要您进行此优化。 要使UNIX上的`xargs`表现出本实验所实现的方式，请将`-n`选项设置为1。例如

```bash
$ echo "1\n2" | xargs -n 1 echo line
line 1
line 2
$
```

**提示：**

- 使用`fork`和`exec`对每行输入调用命令，在父进程中使用`wait`等待子进程完成命令。
- 要读取单个输入行，请一次读取一个字符，直到出现换行符（'\n'）。
- *kernel/param.h*声明`MAXARG`，如果需要声明`argv`数组，这可能很有用。
- 将程序添加到*Makefile*中的`UPROGS`。
- 对文件系统的更改会在qemu的运行过程中保持不变；要获得一个干净的文件系统，请运行`make clean`，然后`make qemu`

`xargs`、`find`和`grep`结合得很好

```bash
$ find . b | xargs grep hello
```

将对“`.`”下面的目录中名为*b*的每个文件运行`grep hello`。

要测试您的`xargs`方案是否正确，请运行shell脚本*xargstest.sh*。如果您的解决方案产生以下输出，则是正确的：

```bash
$ make qemu
...
init: starting sh
$ sh < xargstest.sh
$ $ $ $ $ $ hello
hello
hello
$ $
```

你可能不得不回去修复你的`find`程序中的bug。输出有许多`$`，因为xv6 shell没有意识到它正在处理来自文件而不是控制台的命令，并为文件中的每个命令打印`$`。

### sh

难度：中等

该实验的要求是修改shell，使其在处理文件中的shell命令时，将shell修改为不打印多余的$。