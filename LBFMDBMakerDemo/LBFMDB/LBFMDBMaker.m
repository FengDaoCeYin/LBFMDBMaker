//
//  LBFMDBMaker.m
//  Test
//
//  Created by 刘博 on 2018/4/27.
//  Copyright © 2018年 刘博. All rights reserved.
//

#import "LBFMDBMaker.h"

typedef enum : NSUInteger {
    LBVALUE_TYPE_TEXT = 0,
    LBVALUE_TYPE_INT,
    LBVALUE_TYPE_DOUBLE,
} LBVALUE_TYPE;//表属性类型枚举(可拓展)

@interface LBFMDBMaker()
@property(nonatomic,copy)NSString* tableName;//当前正在操作的表名，主要用以输出日志
@end
@implementation LBFMDBMaker

-(instancetype)init
{
    self = [super init];
    if (self) {
        _sqlString = [NSMutableString string];
        _commons = [NSMutableArray array];
    }
    return self;
}

-(LBFMDBMaker *(^)(NSString *, NSArray<NSString *> *, NSArray*))Table
{
    return ^LBFMDBMaker*(NSString* tableName,NSArray<NSString*>*properties,NSArray* propertyTypes){
        
        if (properties.count != propertyTypes.count) {
            NSLog(@"传参有误！\n方法：%s\nline:%d",__func__, __LINE__);
            return self;
        }
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (private_id integer PRIMARY KEY AUTOINCREMENT,",tableName];
        for (int idx=0; idx<properties.count; idx++) {
            
            [_sqlString appendFormat:@"%@ ",properties[idx]];
            
            switch ([propertyTypes[idx] intValue]) {
                case LBVALUE_TYPE_TEXT:
                    [_sqlString appendString:@"text NOT NULL,"];
                    break;
                case LBVALUE_TYPE_INT:
                    [_sqlString appendString:@"integer NOT NULL,"];
                    break;
                case LBVALUE_TYPE_DOUBLE:
                    [_sqlString appendString:@"double NOT NULL,"];
                    break;
            }
        }
        
        _sqlString = [[_sqlString substringToIndex:_sqlString.length-1] mutableCopy];
        [_sqlString appendString:@")"];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString*tableName,NSArray<NSString *> *, NSArray *))Insert
{
    return ^LBFMDBMaker*(NSString*tableName,NSArray<NSString *> *properties, NSArray * values){
        
        if (properties.count != values.count) {
            NSLog(@"传参有误！\n方法：%s\nline:%d",__func__, __LINE__);
            return self;
        }
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"INSERT INTO %@(",tableName];
        NSMutableString * valueString = [NSMutableString stringWithString:@" VALUES("];
        for (int idx = 0; idx<properties.count; idx++) {
            [_sqlString appendFormat:@"%@,",properties[idx]];
            [valueString appendFormat:@"%@,",[self valueToSqlString:values[idx]]];
        }
        _sqlString = [[_sqlString substringToIndex:_sqlString.length-1] mutableCopy];
        [_sqlString appendString:@")"];
        
        valueString = [[valueString substringToIndex:valueString.length-1] mutableCopy];
        [valueString appendString:@")"];
        
        [_sqlString appendString:valueString];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *))Delete
{
    return ^LBFMDBMaker*(NSString *tableName){
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"DELETE FROM %@",tableName];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *, NSString *, id))Update
{
    return ^LBFMDBMaker*(NSString *tableName,NSString*property,id value){
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ = %@",tableName,property,[self valueToSqlString:value]];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *))Where
{
    return ^LBFMDBMaker*(NSString *termStr){
        [_sqlString appendFormat:@" WHERE %@",termStr];
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *))Select
{
    return ^LBFMDBMaker*(NSString* tableName){
        
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"SELECT * FROM %@",tableName];
        
        _tableName = tableName;
        
        return self;
    };
}

-(LBFMDBMaker *(^)(NSString *, NSString *, int))addColumn {
    return ^LBFMDBMaker*(NSString* tableName,NSString* column,int valueType){
        [self saveCommon];
        
        _sqlString = [NSMutableString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@",tableName,column];
        
        switch (valueType) {
            case LBVALUE_TYPE_TEXT:
                [_sqlString appendString:@" text"];
                break;
            case LBVALUE_TYPE_INT:
                [_sqlString appendString:@" integer"];
                break;
            case LBVALUE_TYPE_DOUBLE:
                [_sqlString appendString:@" double"];
                break;
        }
        
        _tableName = tableName;
        
        return self;
    };
}

-(void)fire:(void (^)(void))handler
{
    [self saveCommon];
    if (_commons.count > 0) {
        [self dbRun:^{
            if (handler) handler();
            _sqlString = [NSMutableString string];
            [_commons removeAllObjects];
            _resultSet = nil;
            _tableName = nil;
        }];
    }
}

#pragma mark - private method
/*
 更新表(增、删、改、查)、创建表
 */
-(void)updataTableWithTableName:(NSString*)tableName SqlStr:(NSString*)sqlStr database:(FMDatabase*)db rollback:(BOOL*)rollback
{
    __block BOOL isSuccess = NO;
    
    if ([sqlStr hasPrefix:@"SELECT"]) {
        _resultSet = [db executeQuery:sqlStr];
    }else{
        isSuccess = [db executeUpdate:sqlStr];
        if (isSuccess) {
            NSLog(@"成功\n%@",sqlStr);
        }else{
            *rollback = YES;
            NSLog(@"失败\n%@",sqlStr);
        }
    }
}

/*
 数据转sql语句字符串
 */
-(NSString*)valueToSqlString:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return [NSString stringWithFormat:@"'%@'",value];
    }
    return [NSString stringWithFormat:@"%@",value];
}

/*
 存储上一条sql语句
 */
-(void)saveCommon
{
    if (_sqlString.length > 0) {
        [_sqlString appendFormat:@";"];
        [_commons addObject:_sqlString];
    }
}

/*
 执行所有已生成并存储的sql语句
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
        NSLog(@"updata:获取数据库失败");
        NSLog(@"%s\nline:%d ",__func__, __LINE__);
    } @finally {
        finish();
    }
}
@end
