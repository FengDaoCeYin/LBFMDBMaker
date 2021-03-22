//
//  FMDBServeCenter.m
//  Test
//
//  Created by 刘博 on 2018/3/28.
//  Copyright © 2018年 刘博. All rights reserved.
//

#import "LBFMDBServeCenter.h"

#define DB_PATH(name) [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:[NSString stringWithFormat:@"/%@.sqlite",name]] //数据库路径

@interface LBFMDBServeCenter()
{
    NSMutableDictionary * _queues;  //存放数据库
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

-(void)operateDBWithName:(NSString *)dbname commonMaker:(void (^)(LBFMDBMaker *))maker
{
    FMDatabaseQueue * opFmdbQueue = [self getDatabaseWithDBName:dbname];
    LBFMDBMaker * lbDBMaker = [[LBFMDBMaker alloc] init];
    lbDBMaker.fmdbQueue = opFmdbQueue;
    if (maker) maker(lbDBMaker);
}

#pragma mark - private method
/*
 * 创建一个FMDatabaseQueue，并存储在本地
 */
-(FMDatabaseQueue*)getDatabaseWithDBName:(NSString*)dbname
{
    if (![_queues objectForKey:dbname]) {
        [_queues setObject:[FMDatabaseQueue databaseQueueWithPath:DB_PATH(dbname)] forKey:dbname];
    }
    return [_queues objectForKey:dbname];
}

@end
