//
//  HCVersionCheck.m
//  HCVersionCheck
//
//  Created by Alicks zhu on 2016/12/1.
//  Copyright © 2016年 HC. All rights reserved.
//

#import "HCVersionCheck.h"
#import <UIKit/UIKit.h>

@interface HCVersionCheck ()
@property (nonatomic, assign) BOOL isIgnore;
@property (nonatomic, assign) BOOL isForce;

@end

@implementation HCVersionCheck

+(void)checkVersionAllowIgnore:(BOOL)ignore{
    
    HCVersionCheck *hcvc = [HCVersionCheck manager];
    hcvc.isIgnore = ignore;
    [hcvc checkVersion];
}


+(void)checkWithDays:(int)days allowIgnore:(BOOL)ignore{
    
    HCVersionInfo *info = [HCVersionInfo versionInfo];
    
    NSDateComponents *cmps = [HCVersionCheck compareDate:info.date];
    if (days > 0 && (cmps.day > days || cmps.month > 0 || cmps.year > 0 )) {
        [HCVersionCheck checkVersionAllowIgnore:ignore];
        [HCVersionInfo saveInfo]; //只有检查之后才保存
    }
    
    if (!cmps) {
        [HCVersionInfo saveInfo];
    }
    
    

}


+(void)checkWithOpenTimes:(int)count allowIgnore:(BOOL)ignore{
    
    
    if (count > 0 && [HCVersionInfo versionInfo].openCounts%count == 0) {
        [HCVersionCheck checkVersionAllowIgnore:ignore];
    }
    [HCVersionInfo saveInfo];
    
}


+(instancetype)manager{
    static HCVersionCheck *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HCVersionCheck alloc]init];
    });
    
    return instance;
}


+(void)ForceUpdate:(BOOL)force{
    HCVersionCheck *vc = [HCVersionCheck manager];
    vc.isForce = force;
}



-(void)checkVersion{
    
    
    [self check:^(NSDictionary *dict) {
        NSLog(@"%s",__func__);
        
        if ([HCVersionInfo versionInfo].ignoreVersion == [dict[@"version"] floatValue])  return ;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发现新版本" message:dict[@"releaseNotes"] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"下次再说" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([HCVersionCheck manager].isForce)   exit(0);
        
        }]];
        
        if ([HCVersionCheck manager].isIgnore && ![HCVersionCheck manager].isForce) {
            [alert addAction:[UIAlertAction actionWithTitle:@"忽略该版本" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                HCVersionInfo *info = [HCVersionInfo versionInfo];
                info.ignoreVersion = [dict[@"version"] floatValue];
                [HCVersionInfo saveVersionInfo:info];
            }]];
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:@"立即更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dict[@"trackViewUrl"]] options:@{} completionHandler:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([HCVersionCheck manager].isForce)   exit(0);
            });
        }]];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];

    } OrFailure:^(NSError *error) {
        
    }];
}



/**
    检查是否有新版本
 @param success 有新版本时会回调
 @param failure 网络连接失败时会回调。没有新版本，不会处理。
 */
-(void)check:(void(^)(NSDictionary *dict))success OrFailure:(void(^)(NSError *error))failure {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleId = infoDict[@"CFBundleIdentifier"];
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@",bundleId]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(!error) //网络连接成功
                {
                    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                    
                    NSInteger resultCount = [responseDict[@"resultCount"] integerValue];
                    if(resultCount==1) //有App数据资料
                    {
                        NSArray *resultArray = responseDict[@"results"];
                        NSDictionary *result = resultArray.firstObject;
                        NSString *version = result[@"version"];
                        if([self isNewVersion:version])//新版本
                        {
                            if (success) success(result);
                        }
                    }

                }
                else
                {
                    if(failure) failure(error);
                }
                
            });
            
        }];
        
        [dataTask resume];
        
    });
}

+(NSDateComponents *)compareDate:(NSString *)dateString{
    // 1.创建一个时间格式化对象
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // 2.格式化对象的样式/z大小写都行/格式必须严格和字符串时间一样
    formatter.dateFormat = @"yyyy年MM月dd日 HH时mm分ss秒 +0800";
    // 3.字符串转换成时间/自动转换0时区/东加西减
    NSDate *date = [formatter dateFromString:dateString];
    NSDate *now = [NSDate date];
    
    // 注意获取calendar,应该根据系统版本判断
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSCalendarUnit type = NSCalendarUnitYear |
    NSCalendarUnitMonth |
    NSCalendarUnitDay |
    NSCalendarUnitHour |
    NSCalendarUnitMinute |
    NSCalendarUnitSecond;
    
    // 4.获取了时间元素
    NSDateComponents *cmps = [calendar components:type fromDate:date toDate:now options:0];
    return cmps;

}

-(BOOL)isNewVersion:(NSString *)newVersion{
    
    return [self newVersion:newVersion moreThanCurrentVersion:[self currentVersion]];
}

-(NSString * )currentVersion{
    
    NSString *key = @"CFBundleShortVersionString";
    NSString * currentVersion = [NSBundle mainBundle].infoDictionary[key];
    return currentVersion;
}

-(BOOL)newVersion:(NSString *)newVersion moreThanCurrentVersion:(NSString *)currentVersion{
    
    if([currentVersion compare:newVersion options:NSNumericSearch]==NSOrderedAscending)
    {
        return YES;
    }
    return NO;
}
@end


#pragma mark ---------------------- 数据保存 --------------------------

@implementation HCVersionInfo


+(void)saveInfo{
    HCVersionInfo *info = [HCVersionInfo versionInfo];
    info.openCounts += 1;
    
    
    NSDate *now = [NSDate date];
    
    // 1.创建一个时间格式化对象
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    // 2.设置时间格式化对象的样式
    formatter.dateFormat = @"yyyy年MM月dd日 HH时mm分ss秒 +0800";
    
    // 3.利用时间格式化对象对时间进行格式化
    info.date = [formatter stringFromDate:now];
    

    
    [HCVersionInfo saveVersionInfo:info];
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        
        self.openCounts = [coder decodeIntForKey:@"openCounts"];
        self.date = [coder decodeObjectForKey:@"date"];
        self.isIgnore = [coder decodeBoolForKey:@"isIgnore"];
        self.ignoreVersion = [coder decodeFloatForKey:@"ignoreVersion"];

        
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:self.openCounts forKey:@"openCounts"];
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeBool:self.isIgnore forKey:@"isIgnore"];
    [coder encodeFloat:self.ignoreVersion forKey:@"ignoreVersion"];
    
}

+(instancetype)versionInfo{
    HCVersionInfo *info = [NSKeyedUnarchiver unarchiveObjectWithFile:HCVersionInfoPath];
    if (!info) {
        info = [[HCVersionInfo alloc]init];
    }
    return info;
    
}

+(void)saveVersionInfo:(HCVersionInfo *)info{
    [NSKeyedArchiver archiveRootObject:info toFile:HCVersionInfoPath];
}

@end
