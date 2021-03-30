//
//  LBFMDBMaker.m
//  Test
//
//  Created by 刘博 on 2018/4/27.
//  Copyright © 2018年 刘博. All rights reserved.
//

#import "LBFMDBMaker.h"

@interface LBFMDBMaker()
@property(nonatomic,copy)NSString* tableName; // 当前正在操作的表名
@property(nonatomic,assign)BOOL hasFire;      // 是否已经执行过操作链
@end
@implementation LBFMDBMaker

-(instancetype)init
{
    if (self = [super init]) {
        _sqlString = [NSMutableString string];
        _commons = [NSMutableArray array];
        _hasFire = NO;
    }
    return self;
}

-(void)setFmdbQueue:(FMDatabaseQueue *)fmdbQueue {
    _fmdbQueue = fmdbQueue;
    
    [fmdbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet* rs = [db executeQuery:@"SELECT count(*) as 'count' FROM sqlite_master WHERE type='table' AND name = 'DBVersion';"];
        BOOL isExist = NO;
        while ([rs next]) {
            isExist = !![rs intForColumn:@"count"];
        }
        if (!isExist) {
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS DBVersion (id integer PRIMARY KEY AUTOINCREMENT,version integer NOT NULL);"];
            [db executeUpdate:@"INSERT INTO DBVersion(version) VALUES(1);"];
            _version = 1;
        } else {
            FMResultSet* versionRS = [db executeQuery:@"SELECT * FROM DBVersion order by id DESC LIMIT 1;"];
            while ([versionRS next]) {
                _version = [versionRS intForColumn:@"version"];
            }
        }
    }];
}

-(LBFMDBMaker *(^)(NSDictionary *))createTable
{
    return ^LBFMDBMaker*(NSDictionary*table){
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",table[@"name"]]; // CREATE TABLE IF NOT EXISTS %@ (private_id integer PRIMARY KEY AUTOINCREMENT,
        
        [table[@"properties"] enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* obj, BOOL * _Nonnull stop) {
            [_sqlString appendFormat:@"%@ ",key];
            
            [self appendValueType:obj SQLStr:_sqlString];
        }];
        
        _sqlString = [[_sqlString substringToIndex:_sqlString.length-1] mutableCopy];
        [_sqlString appendString:@")"];
        
        _tableName = table[@"name"];
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *, NSDictionary *))insert
{
    return ^LBFMDBMaker*(NSString*tableName,NSDictionary*insertData){
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"INSERT INTO %@(",tableName];
        NSMutableString * valueString = [NSMutableString stringWithString:@" VALUES("];
        
        [insertData enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* obj, BOOL * _Nonnull stop) {
            [_sqlString appendFormat:@"%@,",key];
            [valueString appendFormat:@"%@,",[self valueToSqlString:obj]];
        }];
        
        _sqlString = [[_sqlString substringToIndex:_sqlString.length-1] mutableCopy];
        [_sqlString appendString:@")"];
        
        valueString = [[valueString substringToIndex:valueString.length-1] mutableCopy];
        [valueString appendString:@")"];
        
        [_sqlString appendString:valueString];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *))deleteData
{
    return ^LBFMDBMaker*(NSString *tableName){
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"DELETE FROM %@",tableName];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *, NSString *, id))update
{
    return ^LBFMDBMaker*(NSString *tableName,NSString*property,id value){
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ = %@",tableName,property,[self valueToSqlString:value]];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *))where
{
    return ^LBFMDBMaker*(NSString *termStr){
        [_sqlString appendFormat:@" WHERE %@",termStr];
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *))select
{
    return ^LBFMDBMaker*(NSString* tableName){
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"SELECT * FROM %@",tableName];
        
        _tableName = tableName;
        
        return self;
    };
}

// TODO: 可拓展判断条件，增加可处理的数据类型
-(LBFMDBMaker *(^)(NSString *, NSString *, NSString *))addColumn
{
    return ^LBFMDBMaker*(NSString* tableName,NSString*column,NSString*columnType){
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",tableName,column];
        
        if ([columnType.lowercaseString isEqualToString:@"string"]) {
            [_sqlString appendString:@"text"];
        }
        else if ([columnType.lowercaseString isEqualToString:@"int"]){
            [_sqlString appendString:@"integer"];
        }
        else if ([columnType.lowercaseString isEqualToString:@"double"]){
            [_sqlString appendString:@"double"];
        }
        else if ([columnType.lowercaseString isEqualToString:@"bool"]){
            [_sqlString appendString:@"bool"];
        } else {
            [_sqlString appendFormat:@"%@",columnType];
        }
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSDictionary *, NSDictionary<NSString *,NSString *> *, int))dataMove
{
    return ^LBFMDBMaker*(NSDictionary*table,NSDictionary<NSString*,NSString*>*relation,int newVersion){
        
        [self saveCommon];
        
        if (newVersion <= _version) {
            [_commons addObject:@"数据迁移版本号错误"];
            return self;
        }
        
        // Step 1.重命名表
        [_commons addObject:[NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@_old;",table[@"name"],table[@"name"]]];
        
        // Step 2.创建新表
        NSMutableString * dataMoveSQL_Step2 = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",table[@"name"]];
        
        // Step 3.导入数据
        NSMutableString * dataMoveSQL_Step3 = [NSMutableString stringWithFormat:@"INSERT INTO %@ (",table[@"name"]];
        
        NSMutableString * dataMoveSQL_Step3_end = [NSMutableString string];
        
        [table[@"properties"] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [dataMoveSQL_Step2 appendFormat:@"%@ ",key];
            [self appendValueType:obj SQLStr:dataMoveSQL_Step2];
            
            [dataMoveSQL_Step3 appendFormat:@"%@,",key];
            [dataMoveSQL_Step3_end appendFormat:@"%@,",relation[key]];
        }];
        
        dataMoveSQL_Step2 = [[dataMoveSQL_Step2 substringToIndex:dataMoveSQL_Step2.length-1] mutableCopy];
        [dataMoveSQL_Step2 appendString:@");"];
        [_commons addObject:dataMoveSQL_Step2];
        
        dataMoveSQL_Step3 = [[dataMoveSQL_Step3 substringToIndex:dataMoveSQL_Step3.length-1] mutableCopy];
        [dataMoveSQL_Step3 appendString:@") SELECT "];
        dataMoveSQL_Step3_end = [[dataMoveSQL_Step3_end substringToIndex:dataMoveSQL_Step3_end.length-1] mutableCopy];
        [dataMoveSQL_Step3 appendString:dataMoveSQL_Step3_end];
        [dataMoveSQL_Step3 appendFormat:@" FROM %@_old;",table[@"name"]];
        [_commons addObject:dataMoveSQL_Step3];
        
        // Step 4.更新sqlite_sequence(无自增主键，则省略)
        //        [_commons addObject:[NSString stringWithFormat:@"UPDATE sqlite_sequence SET seq = %d WHERE name = '%@';",(表内存储数据量),tableName]];
        
        // Step 5.删除重命名的表
        [_commons addObject:[NSString stringWithFormat:@"DROP TABLE %@_old;",table[@"name"]]];
        
        // Step 6.更新数据库版本
        self.insert(@"DBVersion",@{@"version":@(newVersion)});
        
        _tableName = table[@"name"];
        
        return self;
    };
}

-(void)fire:(void (^)(void))handler
{
    if (_hasFire) @throw [NSException exceptionWithName:@"数据库操作错误" reason:@"重复调用fire函数。" userInfo:nil];
    [self saveCommon];
    if (_commons.count > 0) {
        [self dbRun:^{
            _hasFire = YES;
            if (handler) {
                handler();
            }
        }];
    }
}

#pragma mark - private method -------- 分割线 ---------

// TODO: 可拓展,增加处理类型
-(void)appendValueType:(NSString*)value SQLStr:(NSMutableString*)SQLStr
{
    if ([value.lowercaseString isEqualToString:@"string"]) {
        [SQLStr appendString:@"text NOT NULL,"];
    }
    else if ([value.lowercaseString isEqualToString:@"int"]){
        [SQLStr appendString:@"integer NOT NULL,"];
    }
    else if ([value.lowercaseString isEqualToString:@"double"]){
        [SQLStr appendString:@"double NOT NULL,"];
    }
    else if ([value.lowercaseString isEqualToString:@"bool"]){
        [SQLStr appendString:@"bool NOT NULL,"];
    } else {
        [SQLStr appendFormat:@"%@ NOT NULL",SQLStr];
    }
}


/*
 * 更新表(增、删、改、查)、创建表
 */
-(void)updataTableWithTableName:(NSString*)tableName SqlStr:(NSString*)sqlStr database:(FMDatabase*)db rollback:(BOOL*)rollback
{
    __block BOOL isSuccess = NO;
    
    if ([sqlStr hasPrefix:@"SELECT"]) {
        _resultSet = [db executeQuery:sqlStr];
    }else{
        isSuccess = [db executeUpdate:sqlStr];
        if (isSuccess) {
//            NSLog(@"========LBFMDBMaker log========\n操作成功\n%@",sqlStr);
        }else{
            *rollback = YES;
            NSLog(@"========LBFMDBMaker log========\n操作失败\n%@",sqlStr);
        }
    }
}

/*
 * 数据转sql语句字符串
 */
-(NSString*)valueToSqlString:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return [NSString stringWithFormat:@"'%@'",value];
    }
    return [NSString stringWithFormat:@"%@",value];
}

/*
 * 存储上一条sql语句
 */
-(void)saveCommon
{
    if (_sqlString.length > 0) {
        if (![_sqlString containsString:@";"]) [_sqlString appendFormat:@";"];
        [_commons addObject:_sqlString];
    }
}

/*
 * 执行所有已生成并存储的sql语句
 */
-(void)dbRun:(void(^)(void))finish
{
    @try {
        [_fmdbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            for (int idx = 0; idx<_commons.count; idx++) {
                NSString * sqlcommon = _commons[idx];
                
                [self updataTableWithTableName:_tableName SqlStr:sqlcommon database:db rollback:rollback];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"========LBFMDBMaker log========\n数据库操作失败");
        NSLog(@"========LBFMDBMaker log========\n%s\nline:%d ",__func__, __LINE__);
    } @finally {
        finish();
    }
}

@end
