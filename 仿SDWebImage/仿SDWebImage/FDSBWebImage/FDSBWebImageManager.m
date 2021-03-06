//
//  FDSBWebImageManager.m
//  仿SDWebImage
//
//  Created by itcastteacher on 17/6/23.
//  Copyright © 2017年 itcastteacher. All rights reserved.
//

#import "FDSBWebImageManager.h"

@interface FDSBWebImageManager ()

/// 队列
@property (nonatomic, strong) NSOperationQueue *queue;
/// 操作缓存池
@property (nonatomic, strong) NSMutableDictionary *opCache;
/// 图片缓存池
@property (nonatomic, strong) NSMutableDictionary *imgMemCache;

@end

@implementation FDSBWebImageManager

+ (instancetype)sharedManager {
    
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    
    return instance;
}

- (instancetype)init {
    
    if (self = [super init]) {
        self.queue = [NSOperationQueue new];
        self.opCache = [NSMutableDictionary new];
        self.imgMemCache = [NSMutableDictionary new];
    }
    return self;
}

- (void)downloadImageWithURLString:(NSString *)URLString completion:(void (^)(UIImage *))completionBlock {
    
    // 在下载图片前,判断是否有缓存
    if ([self checkCache:URLString]) {
        if (completionBlock != nil) {
            completionBlock([self.imgMemCache objectForKey:URLString]);
            return;
        }
    }
    
    // 在建立下载操作前,判断要建立的下载操作是否存在,如果存在,就不要再建立重复的下载操作
    if ([self.opCache objectForKey:URLString] != nil) {
        return;
    }
    
    // 获取随机的图片地址,交给DownloadOperation去下载
    DownloadOperation *op = [DownloadOperation downloadOperationWithURLString:URLString finished:^(UIImage *image) {
        
        // 单例把拿到的图片对象回调给VC
        if (completionBlock != nil) {
            completionBlock(image);
        }
        
        // 实现内存缓存
        if (image != nil) {
            [self.imgMemCache setObject:image forKey:URLString];
        }
        
        // 图片下载结束后,移除对应的下载操作
        [self.opCache removeObjectForKey:URLString];
    }];
    
    // 把操作添加到操作缓存池
    [self.opCache setObject:op forKey:URLString];
    
    // 把自定义操作添加到队列
    [self.queue addOperation:op];
}

/// 判断是否有缓存的主方法
- (BOOL)checkCache:(NSString *)URLString {
    
    // 判断是否有内存缓存
    if ([self.imgMemCache objectForKey:URLString]) {
        NSLog(@"从内存中加载... ");
        return YES;
    }
    
    // 判断是否有沙盒缓存
    UIImage *cacheImage = [UIImage imageWithContentsOfFile:[URLString appendCachePath]];
    if (cacheImage != nil) {
        NSLog(@"从沙盒中加载... ");
        [self.imgMemCache setObject:cacheImage forKey:URLString];
        return YES;
    }
    
    return NO;
}

- (void)cancelLastOperation:(NSString *)lastURLString {
    
    // 取出上一个图片的下载操作,调用cancel方法,取消掉
    DownloadOperation *lastOP = [self.opCache objectForKey:lastURLString];
    [lastOP cancel];
    
    // 取消掉的操作,需要从操作缓存池移除
    [self.opCache removeObjectForKey:lastURLString];
}

@end
