# Hash相关概念

**Hash算法**:也被称为散列算法、消息摘要算法、杂凑算法，虽然被称为算法，但实际上它更像是一种思想。Hash算法没有一个固定的公式，只要符合散列思想的算法都可以被称为是Hash算法。其核心思想是:是把任意长度的输入（又叫做预映射pre-image）通一个函数f=F(v)变换成固定长度的输出，f就叫散列值，F()就叫做哈希函数。这是一种压缩映射，也就是，散列值的空间通常远小于输入的空间，不同的输入可能会散列成相同的输出，所以无法从散列值来确定唯一的输入值。


**哈希冲突**:两个不同的输入，得到了相同的散列值称为哈希冲突。


**HashTable**:哈希表，是一种基于哈希算法的数据结构。这种数据结构能够通过关键字Key迅速找到Value值所在的位置，它通过把关键码值映射到表中一个位置来访问记录，以加快查找的速度。这个映射函数即散列函数，存放记录的数组叫做散列表。大部分语言中的哈希表一般由 数组 + 哈希函数 + 链表组成，也有只有数组不用链表的哈希表，前者用的是“链地址法”,后者用的是“开放地 址法”。哈希表优点:查找迅速，缺点:无法遍历。

**iOS中用到的哈希表**:字典、weak、关联数据等。

