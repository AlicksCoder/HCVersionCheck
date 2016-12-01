//
//  HCVersionCheck.h
//  HCVersionCheck
//
//  Created by Alicks zhu on 2016/12/1.
//  Copyright © 2016年 HC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HCVersionInfoPath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"hcversioninfo.archive"]

@interface HCVersionCheck : NSObject


/** 检查更新 ignore 允许用户忽略该版本*/
+(void)checkVersionAllowIgnore:(BOOL)ignore;

/** 检查更新 count 表示 App每多少次程序启动，检查一次更新。 1 表示每次启动都检查更新， 2 表示每2次app启动 检查一次更新*/
+(void)checkWithOpenTimes:(int)count allowIgnore:(BOOL)ignore;

/** 检查更新 days 表示 每过几天，检查一次更新。 1 表示每天第一次启动都检查更新， 2 表示每过2天 检查一次更新   */
+(void)checkWithDays:(int)days allowIgnore:(BOOL)ignore;


@end



#pragma mark =============================数据保存==============================
@interface HCVersionInfo : NSObject

/**
    用于记录调用次数
 */
@property (nonatomic, assign) int openCounts;

@property (nonatomic, strong) NSString *date;

@property (nonatomic, assign) BOOL isIgnore;

@property (nonatomic, assign) float ignoreVersion;


/**
    自动保存数据
 */
+(void)saveInfo;

+(instancetype)versionInfo;
+(void)saveVersionInfo:(HCVersionInfo *)info;
@end
