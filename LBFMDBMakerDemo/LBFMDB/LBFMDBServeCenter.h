//
//  FMDBServeCenter.h
//  Test
//
//  Created by 刘博 on 2018/3/28.
//  Copyright © 2018年 刘博. All rights reserved.
//
//此类是项目所有数据库的统一控制类。用以创建并保存所有已初始化的FMDatabaseQueue。
//可以防止数据库对象的重复创建，运用FMDatabaseQueue保证线程安全。
//数据库路径目前定义死，为Document文件夹下。
//

#import <Foundation/Foundation.h>
#import "LBFMDBMaker.h"

@interface LBFMDBServeCenter : NSObject
/*
 *项目所有数据库的操控中心(单例)
 */
+(id)sharedFMDBCenter;

/*
 *选择要操作的数据库，返回给业务类maker
 *参数解释：
 *1.dbname:数据库名称
 *2.maker:用以与业务类通讯的block
 */
-(void)operateDBWithDBName:(NSString*)dbname lb_makeSQLCommon:(void(^)(LBFMDBMaker*))maker;

@end
