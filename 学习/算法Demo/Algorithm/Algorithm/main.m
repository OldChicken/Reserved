//
//  main.m
//  Algorithm
//
//  Created by Lechech on 2021/3/4.
//

#import <Foundation/Foundation.h>




/*
 给定一个非空整数数组，除了某个元素只出现一次以外，其余每个元素均出现两次。找出那个只出现了一次的元素。

 说明：

 你的算法应该具有线性时间复杂度。 你可以不使用额外空间来实现吗？

 示例 1:

 输入: [2,2,1]
 输出: 1

 示例 2:

 输入: [4,1,2,1,2]
 输出: 4
 */

int getOnceNumber(int *input,int length) {
    for (int i = 1; i < length; i ++) {
        input[0] = input[0] ^ input[i];
    }
    return input[0];
}



//=======================================================


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 第一题
        int a[] = {77,3,3,5,5,6,6,100,100,55,55};
        int length = sizeof(a)/sizeof(a[0]);
        int result = getOnceNumber(a, length);
        NSLog(@"result = %d",result);
    }
    return 0;
}
