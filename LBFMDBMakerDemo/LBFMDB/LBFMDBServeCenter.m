//
//  FMDBServeCenter.m
//  Test
//
//  Created by 刘博 on 2018/3/28.
//  Copyright © 2018年 刘博. All rights reserved.
//

#import "LBFMDBServeCenter.h"

#define DB_PATH(name) [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:[NSString stringWithFormat:@"/%@.sqlite",name]]//数据库路径

@interface LBFMDBServeCenter()
{
    NSMutableDictionary * _queues;//保存项目中已创建的FMDatabaseQueue
}
@end

@implementation LBFMDBServeCenter

static LBFMDBServeCenter * fmdbServeCenter = nil;
+(id)sharedFMDBCenter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmdbServeCenter = [[LBFMDBServeCenter alloc] init];
        fmdbServeCenter->_queues = [NSMutableDictionary dictionary];
    });
    return fmdbServeCenter;
}

-(void)operateDBWithDBName:(NSString *)dbname lb_makeSQLCommon:(void (^)(LBFMDBMaker *))maker
{
    FMDatabaseQueue * opFmdbQueue = [self getDatabaseWithDBName:dbname];
    LBFMDBMaker * lbDBMaker = [[LBFMDBMaker alloc] init];
    lbDBMaker.fmdbQueue = opFmdbQueue;
    maker(lbDBMaker);
}

#pragma mark 私有方法
/*
 *创建一个FMDatabaseQueue
 *已经创建的FMDatabaseQueue对象会保存在queues
 */
-(FMDatabaseQueue*)getDatabaseWithDBName:(NSString*)dbname
{
    if (![_queues objectForKey:dbname]) {
        [_queues setObject:[FMDatabaseQueue databaseQueueWithPath:DB_PATH(dbname)] forKey:dbname];
    }
    return [_queues objectForKey:dbname];
}

@end
