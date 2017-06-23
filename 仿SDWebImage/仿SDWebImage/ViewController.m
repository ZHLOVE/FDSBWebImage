//
//  ViewController.m
//  仿SDWebImage
//
//  Created by itcastteacher on 17/6/23.
//  Copyright © 2017年 itcastteacher. All rights reserved.
//

#import "ViewController.h"
#import "DownloadOperation.h"
#import "AFNetworking.h"
#import "APPModel.h"
#import "YYModel.h"

@interface ViewController ()

/// 模型数组
@property (nonatomic, strong) NSArray *appList;
/// 队列
@property (nonatomic, strong) NSOperationQueue *queue;
/// 操作缓存池
@property (nonatomic, strong) NSMutableDictionary *opCache;
/// 图片控件
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
/// 记录上一次图片的地址
@property (nonatomic, copy) NSString *lastURLString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 准备队列
    self.queue = [NSOperationQueue new];
    // 准备操作缓存池
    self.opCache = [[NSMutableDictionary alloc] init];
    
    [self loadData];
}

/// 测试DownloadOperation : 点击屏幕,随机获取图片的地址,交给DownloadOperation去下载
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    // 获取随机图片地址
    int random = arc4random_uniform((uint32_t)self.appList.count);
    // 获取随机的模型
    APPModel *app = self.appList[random];
    
    // 在建立下载操作前,判断连续传入的图片地址是否一样,如果不一样,就把前一个下载操作取消掉
    if (![app.icon isEqualToString:_lastURLString] && _lastURLString != nil) {
        
        // 取出上一个图片的下载操作,调用cancel方法,取消掉
        DownloadOperation *lastOP = [self.opCache objectForKey:_lastURLString];
        [lastOP cancel];
        
        // 取消掉的操作,需要从操作缓存池移除
        [self.opCache removeObjectForKey:_lastURLString];
    }
    
    // 记录上次图片地址
    _lastURLString = app.icon;
    
    // 获取随机的图片地址,交给DownloadOperation去下载
    DownloadOperation *op = [DownloadOperation downloadOperationWithURLString:app.icon finished:^(UIImage *image) {
        self.iconImageView.image = image;
        
        // 图片下载结束后,移除对应的下载操作
        [self.opCache removeObjectForKey:app.icon];
    }];
    
    // 把操作添加到操作缓存池
    [self.opCache setObject:op forKey:app.icon];
    
    // 把自定义操作添加到队列
    [self.queue addOperation:op];
}

// 获取JSON数据 : 测试DownloadOperation的数据的来源,拿到数据后再去点击屏幕
- (void)loadData {
    
    NSString *URLString = @"https://raw.githubusercontent.com/zhangxiaochuZXC/SHHM06/master/apps.json";
    
    [[AFHTTPSessionManager manager] GET:URLString parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // AFN会自动的JSON数据进行反序列化 : responseObject就是JSON反序列化完成后的结果
        NSArray *dictArr = responseObject;
        self.appList = [NSArray yy_modelArrayWithClass:[APPModel class] json:dictArr];
        NSLog(@"%@",self.appList);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
