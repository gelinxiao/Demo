//
//  NSObject+XL_KVO.m
//  KVC_KVO_Demo
//
//  Created by 葛林晓 on 2021/12/11.
//

#import "NSObject+XL_KVO.h"
#import <objc/message.h>

@interface XLKVOInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) NSKeyValueObservingOptions options;
@property (nonatomic, copy) void(^block)(NSDictionary *change);

@end

@implementation XLKVOInfo

- (instancetype)initWithObserver:(NSObject *)observer key:(NSString *)key options:(NSKeyValueObservingOptions)options block:(void(^)(NSDictionary *change))block {
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _options = options;
        _block = block;
    }
    return self;
}

@end


@implementation NSObject (XL_KVO)

#pragma mark - interface

- (void)xl_addObserver:(NSObject *)observer forKey:(NSString *)key options:(NSKeyValueObservingOptions)options block:(void(^)(NSDictionary *change))block {
    //0 条件判断
    if (nil == observer || nil == key) {
        return;
    }
    if (![self existSetterMethodForKey:key]) {
        return;
    }
    
    //1 保存信息
    NSMutableDictionary *infosMap = [self infosMap];
    if (!infosMap) {
        infosMap = [NSMutableDictionary dictionaryWithCapacity:1];
        [self setInfosMap:infosMap];
    }
    
    XLKVOInfo *info = infosMap[key];
    // 已经观察的key，不再重复
    if (info) {
        return;
    }
    
    info = [[XLKVOInfo alloc] initWithObserver:observer key:key options:options block:block];
    infosMap[key] = info;

    
    //2 创建子类
    Class childClass = [self childClassWithKey:key];
    
    //3 更改 isa 指向为 子类
    object_setClass(self, childClass);
}

- (void)xl_removeObserver:(NSObject *)observer forKey:(NSString *)key {
    NSMutableDictionary *infosMap = [self infosMap];
    [infosMap removeObjectForKey:key];
    
    if (infosMap.count == 0) {
        [self setInfosMap:nil];
        object_setClass(self, class_getSuperclass(object_getClass(self)));
    }
}

#pragma mark - overwrite

static void xl_setter(id self, SEL _cmd, id newValue) {
    //0 获取老值
    NSString *key = [self getterKeyFromSetterString:NSStringFromSelector(_cmd)];
    id oldValue = [self valueForKey:key];
    
    //1 给属性赋值
    struct objc_super superObject = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };
    objc_msgSendSuper(&superObject, _cmd, newValue);
    
    //2 通知观察者
    NSMutableDictionary *infosMap = [self infosMap];
    XLKVOInfo *info = infosMap[key];
    if (info) {
        NSMutableDictionary *change = [NSMutableDictionary dictionaryWithCapacity:2];
        change[@"old"] = oldValue;
        change[@"new"] = newValue;
        if (info.block) {
            info.block(change);
        } else {
            [info.observer observeValueForKeyPath:key ofObject:self change:change context:NULL];
        }
    }
}

Class xl_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

// isa 指回去，清空 InfosMap
static void xl_dealloc(id self, SEL _cmd) {
    [self setInfosMap:nil];
    object_setClass(self, class_getSuperclass(object_getClass(self)));
}


#pragma mark - private

static NSString * const kXLKVOPrefix = @"XLKVONotifying_";

- (Class)childClassWithKey:(NSString *)key {
    NSString *className = NSStringFromClass([self class]);
    NSString *childClassName = [NSString stringWithFormat:@"%@%@",kXLKVOPrefix,className];
    Class childClass = NSClassFromString(childClassName);
    // 防止重复创建生成新类
    if (childClass) return childClass;
    /**
     * 如果内存不存在,创建生成
     * 参数一: 父类
     * 参数二: 新类的名字
     * 参数三: 新类的开辟的额外空间
     */
    //1 申请类
    childClass = objc_allocateClassPair([self class], childClassName.UTF8String, 0);
    //2 注册类
    objc_registerClassPair(childClass);
    
    //2.1 : 添加class 方法
    SEL classSEL = NSSelectorFromString(@"class");
    Method classMethod = class_getInstanceMethod([self class], classSEL);
    const char *classTypes = method_getTypeEncoding(classMethod);
    class_addMethod(childClass, classSEL, (IMP)xl_class, classTypes);
    //2.2 : 添加setter
    SEL setterSEL = [self setterSELForKey:key];
    Method setterMethod = class_getInstanceMethod([self class], setterSEL);
    const char *setterTypes = method_getTypeEncoding(setterMethod);
    class_addMethod(childClass, setterSEL, (IMP)xl_setter, setterTypes);
    //2.3 : 添加dealloc
    SEL deallocSEL = NSSelectorFromString(@"dealloc");
    Method deallocMethod = class_getInstanceMethod([self class], deallocSEL);
    const char *deallocTypes = method_getTypeEncoding(deallocMethod);
    class_addMethod(childClass, deallocSEL, (IMP)xl_dealloc, deallocTypes);
    
    return childClass;
}


- (BOOL)existSetterMethodForKey:(NSString *)key {
    SEL setterSEL = [self setterSELForKey:key];
    Method setterMethod = class_getInstanceMethod(object_getClass(self), setterSEL);
    return (setterMethod != nil);
}

- (SEL)setterSELForKey:(NSString *)key {
    NSString *Key = key.capitalizedString;
    NSString *setKey = [NSString stringWithFormat:@"set%@:",Key];
    return NSSelectorFromString(setKey);
}

- (NSString *)getterKeyFromSetterString:(NSString *)setterString {
    //setKey to key
    NSString *key = [setterString substringWithRange:NSMakeRange(3, setterString.length - 4)];
    key = key.lowercaseString;
    
    return key;
}

static NSString * const kXLAssociatedObjectKey = @"kXLAssociatedObjectKey";

- (NSMutableDictionary *)infosMap {
    return objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kXLAssociatedObjectKey));
}

- (void)setInfosMap:(NSMutableDictionary *)infosMap {
    objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kXLAssociatedObjectKey), infosMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
