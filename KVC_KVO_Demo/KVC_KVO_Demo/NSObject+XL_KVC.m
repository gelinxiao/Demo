//
//  NSObject+XL_KVC.m
//  KVC_KVO_Demo
//
//  Created by 葛林晓 on 2021/12/8.
//

#import "NSObject+XL_KVC.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (XL_KVC)

#pragma mark - set

- (void)xl_setValue:(id)value forKey:(NSString *)key {
    // 1: 判断什么 key
    if (key == nil || key.length == 0) { return; }
    
    // 2: setter set<Key>: or _set<Key> or setIs<Key>
    // key 要大写
    NSString *Key = key.capitalizedString;
    // 拼接方法
    NSString *setKey = [NSString stringWithFormat:@"set%@:",Key];
    NSString *_setKey = [NSString stringWithFormat:@"_set%@:",Key];
    NSString *setIsKey = [NSString stringWithFormat:@"setIs%@:",Key];
    
    if ([self xl_performSelectorWithMethodName:setKey value:value]) {
        return;
    }
    if ([self xl_performSelectorWithMethodName:_setKey value:value]) {
        return;
    }
    if ([self xl_performSelectorWithMethodName:setIsKey value:value]) {
        return;
    }
    
    //3: accessInstanceVariablesDirectly
    if (![self.class accessInstanceVariablesDirectly]) {
        @throw [NSException exceptionWithName:@"UnknownKeyException" reason:[NSString stringWithFormat:@"****[%@ setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key name.****",self] userInfo:nil];
    }
    
    //4: 顺序查找实例变量 _<key>, _is<Key>, <key>,  is<Key>
    NSDictionary *ivarList = [self getIvarList];
    NSArray *names = ivarList.allKeys;
    NSString *_key = [NSString stringWithFormat:@"_%@",key];
    NSString *_isKey = [NSString stringWithFormat:@"_is%@",Key];
    NSString *isKey = [NSString stringWithFormat:@"is%@",Key];
    NSValue *ivarValue = nil;
    if ([names containsObject:_key]) {
        ivarValue = ivarList[_key];
    }else if ([names containsObject:_isKey]) {
        ivarValue = ivarList[_isKey];
    }else if ([names containsObject:key]) {
        ivarValue = ivarList[key];
    }else if ([names containsObject:isKey]) {
        ivarValue = ivarList[isKey];
    }
    if (ivarValue) {
        Ivar ivar = NULL;
        [ivarValue getValue:&ivar size:sizeof(ivar)];
        object_setIvar(self, ivar, value);
        return;
    }
    
    //5: exception
    @throw [NSException exceptionWithName:@"UnknownKeyException" reason:[NSString stringWithFormat:@"****[%@ setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key name.****",self] userInfo:nil];
}

#pragma mark - get

- (id)xl_valueForKey:(NSString *)key {
    // 1: 判断什么 key
    if (key == nil || key.length == 0) { return nil; }

    // 2: 查找方法 get<Key>, <key>, is<Key>,  _<key> ; 没写 NSSet 方法
    // key 要大写
    NSString *Key = key.capitalizedString;
    // 拼接方法
    NSString *getKey = [NSString stringWithFormat:@"get%@:",Key];
    NSString *isKey = [NSString stringWithFormat:@"is%@:",Key];
    NSString *_key = [NSString stringWithFormat:@"_%@",key];
    if ([self respondsToSelector:NSSelectorFromString(getKey)]) {
        return objc_msgSend(self, NSSelectorFromString(getKey));
    }
    if ([self respondsToSelector:NSSelectorFromString(key)]) {
        return objc_msgSend(self, NSSelectorFromString(key));
    }
    if ([self respondsToSelector:NSSelectorFromString(isKey)]) {
        return objc_msgSend(self, NSSelectorFromString(isKey));
    }
    if ([self respondsToSelector:NSSelectorFromString(_key)]) {
        return objc_msgSend(self, NSSelectorFromString(_key));
    }
    
    //NSArray 访问方法
    NSString *countOfKey = [NSString stringWithFormat:@"countOf%@",Key];
    if ([self respondsToSelector:NSSelectorFromString(countOfKey)]) {
        NSString *objectInKeyAtIndex = [NSString stringWithFormat:@"objectIn%@AtIndex:",Key];
        if ([self respondsToSelector:NSSelectorFromString(objectInKeyAtIndex)]) {
            NSUInteger count = (NSUInteger)objc_msgSend(self, NSSelectorFromString(countOfKey));
            //NSKeyValueArray
            NSMutableArray *data = [NSMutableArray arrayWithCapacity:count];
            for (int i = 0; i < count; i ++) {
                id one = objc_msgSend(self, NSSelectorFromString(objectInKeyAtIndex), i);
                [data addObject:one];
            }
            return data;
        }
        
        //objectInKeyAtIndexs
    }
    
    //NSSet 访问方法

    
    // 3: accessInstanceVariablesDirectly
    if (![self.class accessInstanceVariablesDirectly]) {
        @throw [NSException exceptionWithName:@"UnknownKeyException" reason:[NSString stringWithFormat:@"****[%@ valueForUndefinedKey:]: this class is not key value coding-compliant for the key name.****",self] userInfo:nil];
    }
    
    // 4: 查找实例变量 _<key>, _is<Key>, <key>,  is<Key>
    NSDictionary *ivarList = [self getIvarList];
    NSArray *names = ivarList.allKeys;
    NSString *_isKey = [NSString stringWithFormat:@"_is%@",Key];
    NSValue *ivarValue = nil;
    if ([names containsObject:_key]) {
        ivarValue = ivarList[_key];
    }else if ([names containsObject:_isKey]) {
        ivarValue = ivarList[_isKey];
    }else if ([names containsObject:key]) {
        ivarValue = ivarList[key];
    }else if ([names containsObject:isKey]) {
        ivarValue = ivarList[isKey];
    }
    if (ivarValue) {
        Ivar ivar = NULL;
        [ivarValue getValue:&ivar size:sizeof(ivar)];
        return object_getIvar(self, ivar);
    }
    
    //5: exception
    @throw [NSException exceptionWithName:@"UnknownKeyException" reason:[NSString stringWithFormat:@"****[%@ valueForUndefinedKey:]: this class is not key value coding-compliant for the key name.****",self] userInfo:nil];
}


#pragma mark - private

- (BOOL)xl_performSelectorWithMethodName:(NSString *)methodName value:(id)value {
    SEL sel = NSSelectorFromString(methodName);
    if ([self respondsToSelector:sel]) {
        objc_msgSend(self, sel, value);
        return YES;
    }
    return NO;
}

- (NSDictionary *)getIvarList{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        const char *ivarNameChar = ivar_getName(ivar);
        NSString *ivarName = [NSString stringWithUTF8String:ivarNameChar];
        dict[ivarName] = [NSValue valueWithBytes:&ivar objCType:@encode(Ivar)];
    }
    free(ivars);
    return dict;
}

@end
