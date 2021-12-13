//
//  NSObject+XL_KVO.h
//  KVC_KVO_Demo
//
//  Created by 葛林晓 on 2021/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (XL_KVO)

- (void)xl_addObserver:(NSObject *)observer forKey:(NSString *)key options:(NSKeyValueObservingOptions)options block:(void(^)(NSDictionary *change))block;

@end

NS_ASSUME_NONNULL_END
