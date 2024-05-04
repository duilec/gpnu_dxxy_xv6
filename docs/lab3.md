# Lab3：多线程

这个实验将让你熟悉多线程编程。你将在用户级线程包中实现线程之间的切换，使用多线程加速程序，并实现一个barrier。

在编写代码之前，你应该确保已经阅读了 xv6 书中的“第 7 章：调度”并研究了相应的代码。

要开始这个实验，请切换到 thread 分支：

```bash
$ git fetch
$ git checkout thread
$ make clean
```

### 用户级线程切换

难度：中等

在这个实验中，你将设计用户级线程系统的上下文切换机制，并实现它。为了帮助你开始，你的 xv6 包含两个文件 `user/uthread.c` 和 `user/uthread_switch.S`，以及一个在 Makefile 中的规则来构建一个 uthread 程序。`uthread.c` 包含了大部分用户级线程包的代码，以及三个简单测试线程的代码。线程包缺少一些创建线程和在线程之间进行切换的代码。

你的任务是制定一个计划来创建线程，并保存/恢复寄存器以在线程之间进行切换，并实现该计划。完成后，`make grade` 应该显示你的解决方案通过了 uthread 测试。

完成后，当你在 xv6 上运行 uthread 时，应该看到以下输出（三个线程可能以不同的顺序启动）：

```
bashCopy code$ make qemu
...
$ uthread
thread_a started
thread_b started
thread_c started
thread_c 0
thread_a 0
thread_b 0
thread_c 1
thread_a 1
thread_b 1
...
thread_c 99
thread_a 99
thread_b 99
thread_c: exit after 100
thread_a: exit after 100
thread_b: exit after 100
thread_schedule: no runnable threads
$
```

此输出来自三个测试线程，每个线程都有一个循环，打印一行并将 CPU 让给其他线程。

但是，此时，由于没有上下文切换代码，你将看不到任何输出。

你需要在 `user/uthread.c` 的 `thread_create()` 和 `thread_schedule()` 中添加代码，以及在 `user/uthread_switch.S` 中的 `thread_switch` 中添加代码。一个目标是确保当 `thread_schedule()` 第一次运行给定线程时，线程执行传递给 `thread_create()` 的函数，使用自己的栈。另一个目标是确保 `thread_switch` 保存了要切换出去的线程的寄存器，并恢复了要切换到的线程的寄存器，并返回到后者线程上次离开的地方。你需要决定在哪里保存/恢复寄存器；修改 `struct thread` 来保存寄存器是一个好计划。你需要在 `thread_schedule` 中添加一个调用 `thread_switch`；你可以传递你需要的任何参数给 `thread_switch`，但意图是从线程 `t` 切换到 `next_thread`。

一些提示：

- `thread_switch` 需要保存/恢复仅保存调用者的寄存器。为什么？
- 你可以在 `user/uthread.asm` 中看到 `uthread` 的汇编代码，这可能有助于调试。
- 为了测试你的代码，通过 `riscv64-linux-gnu-gdb` 逐步执行你的 `thread_switch` 可能有所帮助。你可以这样开始：

```
bashCopy code(gdb) file user/_uthread
Reading symbols from user/_uthread...
(gdb) b uthread.c:60
```

这在 `uthread.c` 的第 60 行设置了断点。断点可能（也可能不会）在你甚至运行 `uthread` 之前触发。这是如何发生的？

一旦你的 xv6 shell 运行了，输入 `uthread`，gdb 将在第 60 行中断。如果你从另一个进程触发了断点，请继续，直到你在 uthread 进程中触发了断点。现在，你可以输入如下命令来检查 uthread 的状态：

```
bash
Copy code
(gdb) p/x *next_thread
```

使用 "x"，你可以检查内存位置的内容：

```
bash
Copy code
(gdb) x/x next_thread->stack
```

你可以跳到 `thread_switch` 的开头：

```
bashCopy code(gdb) b thread_switch
(gdb) c
```

你可以使用以下命令逐步执行汇编指令：

```
bash
Copy code
(gdb) si
```

GDB 的在线文档在这里。

### 使用用户级线程

难度：中等

在这个任务中，你将使用线程和锁来并行编程，使用哈希表。你应该在具有多个核心的实际 Linux 或 MacOS 计算机上完成这个任务。大多数最近的笔记本电脑都有多核处理器。

此任务使用 UNIX pthread 线程库。你可以从手册页中找到有关它的信息，使用 `man pthreads` 命令，你也可以在网上找到相关信息，例如这里、这里和这里。

文件 `notxv6/ph.c` 包含一个简单的哈希表，如果从单个线程使用则正确，但在多个线程使用时则不正确。在你的主 xv6 目录下（也许是 `~/xv6-labs-2021`），输入以下命令：

```
bashCopy code$ make ph
$ ./ph 1
```

请注意，为了构建 `ph`，Makefile 使用你的操作系统的 gcc，而不是 6.1810 工具。`ph` 的参数指定执行 put 和 get 操作的线程数。运行一段时间后，`ph 1` 会产生类似于以下内容的输出：

```
bashCopy code100000 puts, 3.991 seconds, 25056 puts/second
0: 0 keys missing
100000 gets, 3.981 seconds, 25118 gets/second
```

你看到的数字可能与此示例输出不同，差别可能会达到两倍或更多，这取决于你的计算机速度如何、是否有多核心以及是否正在执行其他任务。

`ph` 运行两个基准测试。首先，它通过调用 `put()` 添加大量键到哈希表中，并打印每秒放入的实际数量。然后，它通过 `get()` 从哈希表中获取键。它打印了应该作为 put 的结果而不在哈希表中的键的数量（在本例中为零），以及它实现的每秒 get 数量。

你可以告诉 `ph` 一次性使用多个线程来同时使用其哈希表，方法是给它一个大于一的参数。试试 `ph 2`：

```
bashCopy code$ ./ph 2
100000 puts, 1.885 seconds, 53044 puts/second
1: 16579 keys missing
0: 16579 keys missing
200000 gets, 4.322 seconds, 46274 gets/second
```

`ph 2` 输出的第一行指示当两个线程同时向哈希表中添加条目时，它们实现了每秒 53,044 次插入的总速率。这大约是从运行 `ph 1` 的单个线程得到的速率的两倍。这是一个优秀的“并行加速”，大约是两倍的核心产生了两倍的工作量（即两倍的速率）。

然而，显示 `16579 keys missing` 的两行指示应该在哈希表中但实际不在那里的大量键。也就是说，put 应该将这些键添加到哈希表中，但是出了问题。查看 `notxv6/ph.c`，特别是 `put()` 和 `insert()`。

为什么使用 2 个线程会导致缺少键，但是使用 1 个线程不会呢？找出一个使用 2 个线程的事件序列，可以导致键丢失。在 `answers-thread.txt` 中提交你的序列并附上简短的解释。

为了避免这种事件序列，可以在 `notxv6/ph.c` 的 `put` 和 `get` 中插入锁定和解锁语句，以便确保使用两个线程时缺少的键始终为 0。相关的 pthread 调用如下：

```
cCopy codepthread_mutex_t lock;            // 声明一个锁
pthread_mutex_init(&lock, NULL); // 初始化锁
pthread_mutex_lock(&lock);       // 获取锁
pthread_mutex_unlock(&lock);     // 释放锁
```

当 `make grade` 表明你的代码通过了 `ph_safe` 测试时，你完成了任务，这要求使用两个线程时缺少的键为零。此时，ph_fast 测试失败是可以接受的。

不要忘记调用 `pthread_mutex_init()`。首先用一个线程测试你的代码，然后用两个线程测试它。它是正确的吗（即你消除了丢失的键）？两个线程的版本是否实现了并行加速（即每单位时间完成了更多的总工作）？

有一些情况下，并发的 `put()` 不会在哈希表中读取或写入重叠的内存，因此不需要锁来保护彼此。你能修改 `ph.c` 以利用这样的情况来为某些 `put()` 获取并行加速吗？提示：每个哈希桶一个锁？

修改你的代码，使一些 `put` 操作并行运行，同时保持正确性。当 `make grade` 表明你的代码通过了 `ph_safe` 和 `ph_fast` 测试时，你完成了任务。`ph_fast` 测试要求两个线程的情况下， `put()` 每秒运行的次数至少是一个线程的 1.25 倍。

### barrier

难度：中等

在这个任务中，你将实现一个屏障：在应用程序中的一个点，所有参与的线程都必须等待，直到所有其他参与的线程也到达该点。你将使用 pthread 条件变量，它是一种类似于 xv6 的 sleep 和 wakeup 的序列协调技术。

你应该在一个实际的计算机上完成这个任务（不是 xv6，不是 qemu）。

文件 `notxv6/barrier.c` 包含一个有问题的屏障。

```
bashCopy code$ make barrier
$ ./barrier 2
barrier: notxv6/barrier.c:42: thread: Assertion `i == t' failed.
```

2 指定了在屏障上同步的线程数（`barrier.c` 中的 `nthread`）。每个线程执行一个循环。在每个循环迭代中，一个线程调用 `barrier()`，然后睡眠一段随机微秒数。断言触发了，因为一个线程在其他线程到达屏障之前离开了屏障。期望的行为是，每个线程在 `barrier()` 中阻塞，直到它们所有的 `nthreads` 都调用了 `barrier()`。

你的目标是实现期望的屏障行为。除了你在 ph 任务中见过的锁原语外，你还需要以下新的 pthread 原语；在这里 和 这里 可以找到详情。

```
cCopy codepthread_cond_wait(&cond, &mutex);  // 在条件上休眠，释放锁 mutex，在唤醒时重新获得
pthread_cond_broadcast(&cond);     // 唤醒所有正在等待条件的线程
```

确保你的解决方案通过了 `make grade` 的屏障测试。

`pthread_cond_wait` 在调用时释放互斥锁，并在返回时重新获取互斥锁。

我们已经给你了 `barrier_init()`。你的任务是实现 `barrier()`，以便不会发生 panic。我们已经为你定义了 `struct barrier`；它的字段供你使用。

有两个问题使你的任务复杂化了：

1. 你必须处理一系列的屏障调用，我们将每次所有线程都到达屏障的情况称为一个 round。`bstate.round` 记录当前 round。每次所有线程到达屏障后，你应该递增 `bstate.round`。
2. 你必须处理一个线程在其他线程退出屏障之前就开始新一轮循环的情况。特别是，你正在从一个 round 到另一个 round 重新使用 `bstate.nthread` 变量。确保一个线程离开屏障并在其他线程之前开始新一轮循环时，不要增加 `bstate.nthread`，而上一个 round 仍在使用它。

使用一个、两个以上两个线程测试你的代码。

### 在Xv6中实现内核级线程和用户级线程

难度：困难