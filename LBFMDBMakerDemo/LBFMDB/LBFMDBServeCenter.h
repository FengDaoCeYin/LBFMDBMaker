//
//  FMDBServeCenter.h
//  Test
//
//  Created by 刘博 on 2018/3/28.
//  Copyright © 2018年 刘博. All rights reserved.
//
//入口类!!!!!
//可以防止数据库对象的重复创建，运用FMDatabaseQueue保证线程安全。
//数据库路径目前定义死，为Document文件夹下。
//

#import <Foundation/Foundation.h>
#import "LBFMDBMaker.h"

@interface LBFMDBServeCenter : NSObject
/*
 项目所有数据库的操控中心(单例)
 */
+(id)sharedFMDBCenter;

/*
 选择要操作的数据库，没有直接创建
 param：
    dbname:数据库名称
    maker:用以与业务类通讯的block
 */
-(void)operateDBWithDBName:(NSString*)dbname lb_makeSQLCommon:(void(^)(LBFMDBMaker*))maker;

@end
