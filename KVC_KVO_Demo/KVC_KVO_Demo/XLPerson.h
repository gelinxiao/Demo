//
//  XLPerson.h
//  KVC_KVO_Demo
//
//  Created by 葛林晓 on 2021/12/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XLPerson : NSObject {
    @public
    NSString *_name;
}

@property (nonatomic, strong) NSString *xlname;
@property (nonatomic, strong) NSArray *arr;
@property (nonatomic, strong) NSSet *set;

@end

NS_ASSUME_NONNULL_END
