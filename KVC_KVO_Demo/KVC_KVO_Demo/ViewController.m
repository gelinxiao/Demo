//
//  ViewController.m
//  KVC_KVO_Demo
//
//  Created by 葛林晓 on 2021/12/8.
//

#import "ViewController.h"
#import "XLPerson.h"
#import "NSObject+XL_KVC.h"
#import "NSObject+XL_KVO.h"

@interface ViewController ()

@property (nonatomic, strong) XLPerson *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [self testKVC];
//    [self testArrKVC];
    [self test_kvo];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.person.xlname = [NSString stringWithFormat:@"%@+",self.person.xlname];
}

- (void)testKVC {
//    XLPerson *p = [XLPerson new];
//    [p xl_setValue:@"xl" forKey:@"name"];
//    NSLog(@"%@",p->_name);
    
//    p->_name = @"xll";
//    NSLog(@"%@", [p xl_valueForKey:@"name"]);
}

- (void)testArrKVC {
    XLPerson *p = [XLPerson new];
    p.arr = @[@"1",@"2",@"3"];
    NSLog(@"%@", [p xl_valueForKey:@"pens"]);
}

void *test_kvo = &test_kvo;
- (void)test_kvo {
    self.person = [XLPerson new];
    self.person.xlname = @"xl";
//    [self.person xl_addObserver:self forKey:@"xlname" options:(NSKeyValueObservingOptionNew) block:^(NSDictionary * _Nonnull change) {
//        NSLog(@"来了VC : %@",change);
//    }];
    [self.person xl_addObserver:self forKey:@"xlname" options:(NSKeyValueObservingOptionNew) block:nil];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"来了VC : %@",change);
}

@end
