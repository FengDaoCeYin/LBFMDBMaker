//
//  LBFMDBMaker.h
//  Test
//
//  Created by 刘博 on 2018/4/27.
//  Copyright © 2018年 刘博. All rights reserved.
//
//此类是数据库操作类，根据链式编程思想，将sql语句的动态生成、及数据库操作交由此类处理。
//目前只实现了简单的数据库操作(增、删、改、查、数据迁移、添加键)，后续可根据情况自行拓展。
//毕竟重点只是体现思路而已，设计会存在不完善，望见谅！
//注：Warning: there is at least one open result set around after performing [FMDatabaseQueue inDatabase:]警告可忽略，resultSet会在数据库关闭时关闭。
//可对.m文件中的checkValueType函数进行拓展，增加数据库存储的数据类型。
//
//某一句指令失败时，数据库会回滚，整个调用链都不会生效。请放心使用。
//

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"

@interface LBFMDBMaker : NSObject

@property(nonatomic,retain)FMDatabaseQueue * fmdbQueue;         //当前maker操作的FMDatabaseQueue
@property(nonatomic,retain,readonly)NSMutableString* sqlString; //当前生成的sqlString
@property(nonatomic,retain,readonly)FMResultSet* resultSet;     //查询数据库的检索结果
@property(nonatomic,retain,readonly)NSMutableArray* commons;    //存储所生成的所有sql语句
@property(nonatomic,assign,readonly)int version; // 正在操作的数据库版本(默认为1)


/*
 * 创建表(如果表存在，则直接操作)
 * table结构示例：
 *   {
 *    name: 'UserInfo',
 *    properties: {
 *      nickname: 'string',
 *      isStudent: 'bool',
 *      weight: 'double',
 *      age: 'int'
 *    }
 *   }
 */
-(LBFMDBMaker*(^)(NSDictionary*table))createTable;

/*
 * 插入数据
 * param：
 *   tableName:表名
 *   data:插入的数据
 * data示例：
 *   {
 *       name:张三,
 *       age:18
 *   }
 */
-(LBFMDBMaker*(^)(NSString*tableName,NSDictionary*data))insert;

/*
 * 删除数据
 * param：
 *   tableName:表名
 * tips：
 *   可与Where配合使用，完善查询条件
 */
-(LBFMDBMaker*(^)(NSString*tableName))deleteData;

/*
 * 改数据
 * param：
 *   tableName:表名
 *   property:更新的属性
 *   value:更新的值
 * tips：
 *   可与Where配合使用，完善条件
 */
-(LBFMDBMaker*(^)(NSString*tableName,NSString*property,id value))update;

/*
 * 查询
 * param：
 *   tableName:表名
 * tips：
 *   可与Where配合使用
 */
-(LBFMDBMaker*(^)(NSString*tableName))select;

/*
 * 条件
 * param：
 *   termStr:条件语句
 * tips：
 *   需自行写正确的sql语句，例如查age属性为18的人，就听该传入"age = 18"
 */
-(LBFMDBMaker*(^)(NSString*termStr))where;

/*
 * 增加键
 * param：
 *   tableName:表名
 *   column:键名称
 *   columnType:数据类型
 */
-(LBFMDBMaker*(^)(NSString*tableName,NSString*column,NSString*columnType))addColumn;

/*
 * 数据迁移（更新表）
 * param：
 *   table:需要迁移的表，键为新的。
 *   relation:新、旧表键的对应关系。
 *   newVersion:数据库新版本（需大于当前版本，才能执行数据迁移）
 * table示例：
 *   {
 *       name:"student",
 *       properties:{
 *           id:string
 *           Name:string
 *       }
 *   }
 * relation示例：
 *   {
 *      name:Name
 *      id:Title
 *   }
 *   旧表的Name、Title，将赋值给新表的name、id。
 * tips：
 *   如上，旧键应与新键对应。迁移数据过程中,会执行"INSERT INTO student (id, Name) SELECT ID, Title FROM student_old;"。
 *
 */
-(LBFMDBMaker*(^)(NSDictionary*table,NSDictionary<NSString*,NSString*>*relation,int newVersion))dataMove;

/*
 * 开始执行数据库操作
 * param：
 *   handler:数据库操作完毕给业务类的回执
 * tips：
 *   执行此次链式操作生成的所有sql语句。此函数也代表一次链式操作的终结，执行完毕后会清空除fmdbQueue的所有属性。
 */
-(void)fire:(void(^)(void))handler;
@end
