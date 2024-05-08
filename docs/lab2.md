# Lab2：系统调用

在上一个实验中，你使用了系统调用来编写一些实用程序。在这个实验中，你将向 xv6 添加一些新的系统调用，这将帮助你理解它们的工作原理，并让你了解 xv6 内核的一些内部结构。你将在以后的实验中添加更多的系统调用。

在开始编码之前，请阅读 xv6 书的第 2 章，以及第 4 章的 4.3 和 4.4 小节，以及相关的源文件：

- 将系统调用路由到内核的用户空间“存根”位于 user/usys.S 中，当你运行 make 时，它由 user/usys.pl 生成。声明位于 user/user.h 中。
- 将系统调用路由到实现它的内核函数的内核空间代码位于 kernel/syscall.c 和 kernel/syscall.h。
- 进程相关的代码位于 kernel/proc.h 和 kernel/proc.c。

要开始这个实验，请切换到 syscall 分支：

```bash
$ git fetch
$ git checkout syscall
$ make clean
```

如果你运行 `make grade`，你会发现评分脚本无法执行 `trace` 和 `sysinfotest`。你的任务是添加必要的系统调用和存根，使它们正常工作。

使用 gdb（简单） 在许多情况下，打印语句足以用于调试内核，但有时单步执行一些汇编代码或检查栈上的变量是有帮助的。

要了解有关如何运行 GDB 以及在使用 GDB 时可能出现的常见问题，请查看这个页面。

为了帮助你熟悉 gdb，请运行 `make qemu-gdb`，然后在另一个窗口中启动 gdb（参见指导页面上的 gdb 项目）。一旦你有了两个窗口，请在 gdb 窗口中键入：

```gdb
(gdb) b syscall
Breakpoint 1 at 0x80002142: file kernel/syscall.c, line 243.
(gdb) c
Continuing.
[Switching to Thread 1.2]

Thread 2 hit Breakpoint 1, syscall () at kernel/syscall.c:243
243     {
(gdb) layout src
(gdb) backtrace
```

layout 命令将窗口分成两部分，显示 gdb 在源代码中的位置。backtrace 打印出栈回溯。请参阅使用 GNU 调试器以获取有用的 GDB 命令。

在 backtrace 输出中查看，哪个函数调用了 syscall？ 键入 n 几次以跳过 `struct proc *p = myproc();` 这条语句。一旦跳过此语句，请键入 `p /x *p`，它以十六进制打印当前进程的 proc 结构（请参阅 kernel/proc.h>）。

p->trapframe->a7 的值是多少？这个值代表什么？（提示：查看 user/initcode.S，xv6 启动的第一个用户程序） 处理器正在内核模式下运行，我们可以打印特权寄存器，如 sstatus（请参阅 RISC-V 特权指令）：

```
(gdb) p /x $sstatus
```

处理器之前的模式是什么？ 在这个实验的后续部分（或后续的实验中），你可能会犯一个编程错误，导致 xv6 内核崩溃。例如，将语句 `num = p->trapframe->a7;` 替换为 `num = * (int *) 0;`，在 syscall 的开头，运行 `make qemu`，你会看到类似以下的内容：

```bash
xv6 kernel is booting

hart 2 starting
hart 1 starting
scause 0x000000000000000d
sepc=0x000000008000215a stval=0x0000000000000000
panic: kerneltrap
```

退出 qemu。 要追踪导致内核页面故障崩溃的错误，搜索内核 kernel.asm 中打印的 sepc 值，该文件包含编译后的内核的汇编代码。

记录内核崩溃时程序计数器所在的汇编指令。哪个寄存器对应于变量 num？ 要检查处理器和内核在发生故障的指令时的状态，启动 gdb，并在发生故障的 epc 处设置断点，如下所示：

```gdb
(gdb) b *0x000000008000215a
Breakpoint 1 at 0x8000215a: file kernel/syscall.c, line 247.
(gdb) layout asm
(gdb) c
Continuing.
[Switching to Thread 1.3]

Thread 3 hit Breakpoint 1, syscall () at kernel/syscall.c:247
```

确认发生故障的汇编指令与上面找到的指令相同。

内核为什么崩溃？提示：查看文本中的图 3-3；地址 0 在内核地址空间中被映射吗？scause 中的值是否证实了这一点？（请参阅 RISC-V 特权指令中 scause 的描述） 请注意，scause 是内核崩溃时打印的，但通常你需要查看其他信息来追踪导致内核崩溃的问题。例如，要找出内核崩溃时正在运行的用户进程，可以打印出该进程的名称：

```gdb
(gdb) p p->name
```

内核崩溃时正在运行的二进制文件的名称是什么？它的进程 ID（pid）是多少？

这是对使用 gdb 追踪错误的简要介绍；当追踪内核错误时，重新阅读使用 GNU 调试器是值得的。指导页面还提供了一些其他有用的调试技巧。

## trace

难度：中等

在这个任务中，你将添加一个系统调用跟踪功能，这可能有助于你在调试后续实验时。你将创建一个新的跟踪系统调用，它将控制跟踪。它应该接受一个参数，一个整数“掩码”，其位指定要跟踪的系统调用。例如，要跟踪 fork 系统调用，程序调用 `trace(1 << SYS_fork)`，其中 `SYS_fork` 是来自 kernel/syscall.h 的系统调用号。你必须修改 xv6 内核，在每个系统调用即将返回时打印一行，如果系统调用的号码在掩码中设置了。这行应该包含进程 ID、系统调用的名称和返回值；你不需要打印系统调用的参数。trace 系统调用应该启用调用它的进程以及它随后 fork 的任何子进程的跟踪，但不应影响其他进程。

我们提供了一个 trace 用户级程序，它运行另一个启用了跟踪的程序（见 user/trace.c）。完成后，你应该看到如下输出：

```bash
$ trace 32 grep hello README
3: syscall read -> 1023
3: syscall read -> 966
3: syscall read -> 70
3: syscall read -> 0
$
$ trace 2147483647 grep hello README
4: syscall trace -> 0
4: syscall exec -> 3
4: syscall open -> 3
4: syscall read -> 1023
4: syscall read -> 966
4: syscall read -> 70
4: syscall read -> 0
4: syscall close -> 0
$
$ grep hello README
$
$ trace 2 usertests forkforkfork
usertests starting
test forkforkfork: 407: syscall fork -> 408
408: syscall fork -> 409
409: syscall fork -> 410
410: syscall fork -> 411
409: syscall fork -> 412
410: syscall fork -> 413
409: syscall fork -> 414
411: syscall fork -> 415
...
$
```

在上面的第一个示例中，trace 调用 grep 仅跟踪 read 系统调用。32 是 1<<SYS_read。在第二个示例中，trace 在跟踪所有系统调用的情况下运行 grep；2147483647 有所有 31 位设置为 1。在第三个示例中，程序未跟踪，因此不会打印出跟踪输出。在第四个示例中，forkforkfork 测试中所有后代 fork 的 fork 系统调用都被跟踪。如果你的程序行为如上所示（尽管进程 ID 可能不同），则你的解决方案是正确的。

一些提示：

- 在 Makefile 中的 `UPROGS` 中添加 `$U/_trace`。
- 运行 `make qemu`，你会看到编译器无法编译 user/trace.c，因为用户空间的系统调用存根尚不存在：在 user/user.h 中为系统调用 sysinfo() 声明原型，使用 `struct sysinfo;` 预先声明 sysinfo 结构的存在，然后在 user/usys.pl 中添加一个存根，最后在 kernel/syscall.h 中添加一个系统调用号。Makefile 调用 perl 脚本 user/usys.pl，它生成了 user/usys.S，实际的系统调用存根，这些存根使用 RISC-V 的 ecall 指令切换到内核。一旦你解决了编译问题，请运行 `trace 32 grep hello README`；它会失败，因为你还没有在内核中实现该系统调用。
- 在 kernel/sysproc.c 中添加一个 `sys_trace()` 函数，通过将其参数存储在 proc 结构的一个新变量中来实现新的系统调用（参见 kernel/proc.h）。从用户空间获取系统调用参数的函数在 kernel/syscall.c 中，并且你可以在 kernel/sysproc.c 中看到它们的使用示例。
- 修改 fork()（参见 kernel/proc.c），将跟踪掩码从父进程复制到子进程。
- 修改 kernel/syscall.c 中的 syscall() 函数以打印跟踪输出。你需要添加一个用于索引系统调用名称的数组。

如果你直接在 qemu 中运行测试用例时通过了，但在使用 `make grade` 运行测试时遇到超时，请尝试在 Athena 上测试你的实现。这个实验中的一些测试可能对你的本地机器来说计算量过大（尤其是如果你使用 WSL）。

## sysinfo

难度：中等

在这个任务中，你将添加一个系统调用 `sysinfo`，它收集关于运行系统的信息。该系统调用接受一个参数：一个指向 `struct sysinfo` 的指针（请参见 kernel/sysinfo.h）。内核应该填充该结构的字段：`freemem` 字段应该设置为空闲内存的字节数，`nproc` 字段应该设置为状态不是 UNUSED 的进程数。我们提供了一个测试程序 `sysinfotest`；如果它打印出“sysinfotest: OK”，则你通过了这个任务。

一些提示：

- 在 Makefile 中的 `UPROGS` 中添加 `$U/_sysinfotest`。

- 运行 `make qemu`；user/sysinfotest.c 会编译失败。添加 `sysinfo` 系统调用，遵循与前面任务相同的步骤。要在 user/user.h 中声明 sysinfo() 的原型，你需要预先声明 `struct sysinfo` 的存在：

  ```c
  struct sysinfo;
  int sysinfo(struct sysinfo *);
  ```

- 一旦你解决了编译问题，请运行 sysinfotest；它会失败，因为你还没有在内核中实现该系统调用。

- sysinfo 需要将一个 `struct sysinfo` 复制回用户空间；请参阅 kernel/sysfile.c 中的 `sys_fstat()` 和 kernel/file.c 中的 `filestat()`，以了解如何使用 `copyout()` 完成这个操作。

- 要收集空闲内存的数量，请在 kernel/kalloc.c 中添加一个函数。

- 要收集进程数量，请在 kernel/proc.c 中添加一个函数。