//
//  NSObject+XL_KVC.h
//  KVC_KVO_Demo
//
//  Created by 葛林晓 on 2021/12/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (XL_KVC)

- (void)xl_setValue:(id)value forKey:(NSString *)key;
- (id)xl_valueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
