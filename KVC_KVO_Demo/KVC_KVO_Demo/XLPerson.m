//
//  XLPerson.m
//  KVC_KVO_Demo
//
//  Created by 葛林晓 on 2021/12/8.
//

#import "XLPerson.h"

@implementation XLPerson

//- (void)setName:(NSString *)name {
//    _name = name;
//    NSLog(@"%s",__func__);
//}

//- (NSString *)name {
//    NSLog(@"%s",__func__);
//    return _name;
//}

//MARK: - 集合类型的走

// 个数
- (NSUInteger)countOfPens{
    NSLog(@"%s",__func__);
    return [self.arr count];
}

// 获取值
- (id)objectInPensAtIndex:(NSUInteger)index {
    NSLog(@"%s",__func__);
    return [NSString stringWithFormat:@"pens %lu", index];
    return [self.arr objectAtIndex:index];
}

//MARK: - set

// 个数
- (NSUInteger)countOfBooks{
    NSLog(@"%s",__func__);
    return [self.set count];
}

// 是否包含这个成员对象
- (id)memberOfBooks:(id)object {
    NSLog(@"%s",__func__);
    return [self.set containsObject:object] ? object : nil;
}

// 迭代器
- (id)enumeratorOfBooks {
    // objectEnumerator
    NSLog(@"来了 迭代编译");
    return [self.arr reverseObjectEnumerator];
}


@end
