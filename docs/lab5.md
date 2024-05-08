# Lab5: 锁的机制

在这个实验中，你将获得重新设计代码以增加并行性的经验。多核机器上锁争用的常见症状是高锁争用。改善并行性通常涉及更改数据结构和锁定策略，以减少争用。你将为 xv6 内存分配器和块缓存进行这样的操作。

在编写代码之前，请确保阅读 xv6 书中的以下部分：

- 第6章：“锁定”以及相应的代码。
- 第8.1至8.3节：“概述”，“缓冲区缓存层”和“代码：缓冲区缓存”。

```bash
$ git fetch
$ git checkout lock
$ make clean
```

## 内存分配器

难度：中等

`user/kalloctest` 程序对 xv6 的内存分配器进行了压力测试：三个进程扩展和收缩它们的地址空间，导致对 `kalloc` 和 `kfree` 的多次调用。`kalloc` 和 `kfree` 获取 `kmem.lock`。`kalloctest` 打印了在获取锁时由于尝试获取另一个核心已经持有的锁而发生的循环迭代次数（作为“#test-and-set”），对于 `kmem` 锁和其他几个锁。在获取时的循环迭代次数是锁争用的一个粗略度量。`kalloctest` 的输出在开始实验之前如下所示：

```bash
$ kalloctest
start test1
test1 results:
--- lock kmem/bcache stats
lock: kmem: #test-and-set 83375 #acquire() 433015
lock: bcache: #test-and-set 0 #acquire() 1260
--- top 5 contended locks:
lock: kmem: #test-and-set 83375 #acquire() 433015
lock: proc: #test-and-set 23737 #acquire() 130718
lock: virtio_disk: #test-and-set 11159 #acquire() 114
lock: proc: #test-and-set 5937 #acquire() 130786
lock: proc: #test-and-set 4080 #acquire() 130786
tot= 83375
test1 FAIL
start test2
total free number of pages: 32497 (out of 32768)
.....
test2 OK
start test3
child done 1
child done 100000
test3 OK
start test2
total free number of pages: 32497 (out of 32768)
.....
test2 OK
start test3
child done 1
child done 100000
test3 OK
```

你可能会看到不同于此处所示的计数，以及前 5 个争用锁的不同顺序。

在获取中，对于每个锁，`acquire` 维护获取该锁的调用计数，以及循环尝试但未能设置锁的次数。`kalloctest` 调用一个系统调用，导致内核打印出对于 `kmem` 和 `bcache` 锁（这是本实验的重点）以及最争用的 5 个锁的这些计数。如果存在锁争用，获取时的循环迭代次数将会很大。系统调用返回 `kmem` 和 `bcache` 锁的循环迭代次数的总和。

对于这个实验，你必须使用一个专用的未加载的多核机器。如果使用正在执行其他任务的机器，`kalloctest` 打印的计数将是无意义的。你可以使用专用的 Athena 工作站，或者你自己的笔记本电脑，但不要使用拨号机器。

在 `kalloctest` 中的锁争用的根本原因是 `kalloc()` 具有单个空闲列表，由单个锁保护。为了消除锁争用，你将不得不重新设计内存分配器，以避免单个锁和列表。基本思路是维护每个 CPU 的自由列表，每个列表都有自己的锁。不同 CPU 上的分配和释放可以并行运行，因为每个 CPU 将在不同的列表上操作。主要的挑战将是处理一个 CPU 的自由列表为空的情况，但另一个 CPU 的列表有空闲内存的情况；在这种情况下，一个 CPU 必须“窃取”另一个 CPU 的部分自由列表。窃取可能会引入锁争用，但这希望是不频繁的。

你的任务是实现每个 CPU 的自由列表，并在 CPU 的自由列表为空时进行窃取。你必须给你的所有锁起名字，以 "kmem" 开头。也就是说，你应该为每个锁调用 `initlock`，并传递一个以 "kmem" 开头的名称。运行 `kalloctest` 来查看你的实现是否减少了锁争用。要检查它是否仍然可以分配所有内存，运行 `usertests sbrkmuch`。你的输出将类似于下面显示的内容，其中对于 `kmem` 锁的总争用大大减少，尽管具体数字可能会有所不同。确保 `usertests -q` 中的所有测试都通过。当你完成后，`make grade` 应该说 `kalloctests` 通过了。

```bash
$ kalloctest
start test1
test1 results:
--- lock kmem/bcache stats
lock: kmem: #test-and-set 0 #acquire() 42843
lock: kmem: #test-and-set 0 #acquire() 198674
lock: kmem: #test-and-set 0 #acquire() 191534
lock: bcache: #test-and-set 0 #acquire() 1262
--- top 5 contended locks:
lock: proc: #test-and-set 43861 #acquire() 117281
lock: virtio_disk: #test-and-set 5347 #acquire() 114
lock: proc: #test-and-set 4856 #acquire() 117312
lock: proc: #test-and-set 4168 #acquire() 117316
lock: proc: #test-and-set 2797 #acquire() 117266
tot= 0
test1 OK
start test2
total free number of pages: 32499 (out of 32768)
.....
test2 OK
start test3
child done 1
child done 100000
test3 OK
$ usertests sbrkmuch
usertests starting
test sbrkmuch: OK
ALL TESTS PASSED
$ usertests -q
...
ALL TESTS PASSED
```

**提示：**

- 你可以使用 `kernel/param.h` 中的常量 `NCPU`。

- 让 `freerange` 将所有空闲内存给运行 `freerange` 的 CPU。

- `cpuid` 函数返回当前核心编号，但只有在关闭中断时才能调用它并使用其结果。你应该使用 `push_off()` 和 `pop_off()` 来关闭和打开中断。

- 查看 `kernel/sprintf.c` 中的 `snprintf` 函数以获取字符串格式化的想法。虽然如此，你可以将所有锁命名为 "kmem"。

- 可选择使用 xv6 的竞争检测器运行你的解决方案：

  ```bash
  $ make clean
  $ make KCSAN=1 qemu
  $ kalloctest
    ..
  ```

  `kalloctest` 可能会失败，但你不应该看到任何竞争。如果 xv6 的竞争检测器观察到竞争，它将打印两个堆栈跟踪，描述了竞争，如下所示：

  ```bash
   == race detected ==
   backtrace for racing load
   0x000000008000ab8a
   0x000000008000ac8a
   0x000000008000ae7e
   0x0000000080000216
   0x00000000800002e0
   0x0000000080000f54
   0x0000000080001d56
   0x0000000080003704
   0x0000000080003522
   0x0000000080002fdc
   backtrace for watchpoint:
   0x000000008000ad28
   0x000000008000af22
   0x000000008000023c
   0x0000000080000292
   0x0000000080000316
   0x000000008000098c
   0x0000000080000ad2
   0x000000008000113a
   0x0000000080001df2
   0x000000008000364c
   0x0000000080003522
   0x0000000080002fdc
   ==========
  ```

  在你的操作系统上，你可以通过将堆栈跟踪剪切并粘贴到 `addr2line` 中将其转换为函数名与行号：

  ```bash
  $ riscv64-linux-gnu-addr2line -e kernel/kernel
   0x000000008000ab8a
   0x000000008000ac8a
   0x000000008000ae7e
   0x0000000080000216
   0x00000000800002e0
   0x0000000080000f54
   0x0000000080001d56
   0x0000000080003704
   0x0000000080003522
   0x0000000080002fdc
   ctrl-d
   kernel/kcsan.c:157
   kernel/kcsan.c:241
   kernel/kalloc.c:174
   kernel/kalloc.c:211
   kernel/vm.c:255
   kernel/proc.c:295
   kernel/sysproc.c:54
   kernel/syscall.c:251
  ```

  你不需要运行竞争检测器，但你可能会发现它很有帮助。请注意，竞争检测器会显着减慢 xv6 的运行速度，因此在运行 `usertests` 时可能不想使用它。

## 块缓存

难度：困难

这个实验的下半部分与第一部分独立；无论你是否完成了第一部分，你都可以在这部分工作（并通过测试）。

如果多个进程密集使用文件系统，则它们可能会争夺 `bcache.lock`，该锁保护在 `kernel/bio.c` 中的磁盘块缓存的列表。`bcachetest` 创建多个进程，重复读取不同的文件以产生对 `bcache.lock` 的争用；在完成此实验之前，它的输出如下所示：

```bash
$ bcachetest
start test0
test0 results:
--- lock kmem/bcache stats
lock: kmem: #test-and-set 0 #acquire() 33035
lock: bcache: #test-and-set 16142 #acquire() 65978
--- top 5 contended locks:
lock: virtio_disk: #test-and-set 162870 #acquire() 1188
lock: proc: #test-and-set 51936 #acquire() 73732
lock: bcache: #test-and-set 16142 #acquire() 65978
lock: uart: #test-and-set 7505 #acquire() 117
lock: proc: #test-and-set 6937 #acquire() 73420
tot= 16142
test0: FAIL
start test1
test1 OK
```

你可能会看到不同的输出，但是 `bcache` 锁的 test-and-set 数量会很高。如果你查看 `kernel/bio.c` 中的代码，你会发现 `bcache.lock` 保护着缓存块缓冲区的列表，每个块缓冲区中的引用计数（`b->refcnt`）以及缓存块的标识（`b->dev` 和 `b->blockno`）。

修改块缓存，使得运行 `bcachetest` 时所有锁的获取循环迭代次数接近于零。理想情况下，所有涉及块缓存的锁的计数总和应该为零，但如果总和小于 500，也是可以接受的。修改 `bget` 和 `brelse`，以便对于在块缓存中的不同块的并发查找和释放不太可能在锁上发生冲突（例如，不必全部等待 `bcache.lock`）。你必须保持一个不变：每个块的缓存中最多有一个副本。完成后，你的输出应类似于下面显示的内容（尽管不完全相同）。确保在你完成后仍然通过了 `usertests -q`。当你完成时，`make grade` 应该通过所有测试。

```bash
$ bcachetest
start test0
test0 results:
--- lock kmem/bcache stats
lock: kmem: #test-and-set 0 #acquire() 32954
lock: kmem: #test-and-set 0 #acquire() 75
lock: kmem: #test-and-set 0 #acquire() 73
lock: bcache: #test-and-set 0 #acquire() 85
lock: bcache.bucket: #test-and-set 0 #acquire() 4159
lock: bcache.bucket: #test-and-set 0 #acquire() 2118
lock: bcache.bucket: #test-and-set 0 #acquire() 4274
lock: bcache.bucket: #test-and-set 0 #acquire() 4326
lock: bcache.bucket: #test-and-set 0 #acquire() 6334
lock: bcache.bucket: #test-and-set 0 #acquire() 6321
lock: bcache.bucket: #test-and-set 0 #acquire() 6704
lock: bcache.bucket: #test-and-set 0 #acquire() 6696
lock: bcache.bucket: #test-and-set 0 #acquire() 7757
lock: bcache.bucket: #test-and-set 0 #acquire() 6199
lock: bcache.bucket: #test-and-set 0 #acquire() 4136
lock: bcache.bucket: #test-and-set 0 #acquire() 4136
lock: bcache.bucket: #test-and-set 0 #acquire() 2123
--- top 5 contended locks:
lock: virtio_disk: #test-and-set 158235 #acquire() 1193
lock: proc: #test-and-set 117563 #acquire() 3708493
lock: proc: #test-and-set 65921 #acquire() 3710254
lock: proc: #test-and-set 44090 #acquire() 3708607
lock: proc: #test-and-set 43252 #acquire() 3708521
tot= 128
test0: OK
start test1
test1 OK
```

请给你的所有锁都起名字，以 "bcache" 开头。也就是说，你应该为每个锁调用 `initlock`，并传递一个以 "bcache" 开头的名称。

在块缓存中减少锁争用比对于 `kalloc` 更加棘手，因为 `bcache` 缓冲区真正被多个进程（以及核心）共享。对于 `kalloc`，可以通过为每个 CPU 提供自己的分配器来消除大多数争用；但对于块缓存，这种方法行不通。我们建议你在哈希表中查找块号，每个哈希桶有一个锁。

在以下情况下，如果你的解决方案有锁冲突，也是可以接受的：

- 当两个进程同时使用相同的块号时。`bcachetest test0` 永远不会这样做。
- 当两个进程同时错过缓存，并且需要找到一个未使用的块来替换。`bcachetest test0` 永远不会这样做。
- 当两个进程同时使用在你用于分区块和锁的任何方案中冲突的块；例如，如果两个进程使用的块的块号哈希到哈希表中的同一槽中。`bcachetest test0` 可能会这样做，具体取决于你的设计，但是你应该尝试调整方案的细节以避免冲突（例如，更改哈希表的大小）。

**以下是一些提示：**

- 阅读 `kernel/bio.c` 中的代码以了解块缓存如何工作。
- 参考 `kernel/param.h` 中的常量 `NBUCKET`。
- 你可能会发现在哈希桶级别上持有锁的设计更简单，而不是在每个块上持有锁的设计。
- 一个可能有用的技巧是将块缓存作为“后备磁盘”来考虑，其中没有并发磁盘访问。

**注意**：在实现并行版本时，确保你的代码仍然正确同步。不要牺牲正确性以实现性能。

完成此任务后，提交代码，并确保所有测试都通过。