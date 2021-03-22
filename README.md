# 前言

近期，因为某些原因，准备替换掉项目中现有的数据库。数据库操作长久以来一直是程序猿们的痛点，稍有不慎，会发生各种问题，而且排查起来多有不便。为了避免SQL拼写错误及简化代码，我基于FMDB框架设计了数据库链式操作方案。

# 类介绍

## 1. LBFMDBServeCenter

入口类，集中控制项目中的数据库。

### 1.1 sharedFMDBCenter

生成sharedFMDBCenter单例。

### 1.2 -(void)operateDBWithName:(NSString*)dbname commonMaker:(void(^)(LBFMDBMaker*))maker

选择要操作的数据库，没有则直接创建。必须通过它开始操作数据库。

## 2. LBFMDBMaker

操作处理类，负责SQL生成及执行。

### 2.1 -(LBFMDBMaker*(^)(NSDictionary*table))createTable

创建表(如果表存在，则直接操作)。

### 2.2 -(LBFMDBMaker*(^)(NSString*tableName,NSDictionary*data))insert

插入数据。注意：data的键要与表的键一致。

### 2.3 -(LBFMDBMaker*(^)(NSString*tableName))deleteData

删除数据。必要时需与where（2.6）搭配使用。

### 2.4 -(LBFMDBMaker*(^)(NSString*tableName,NSString*property,id value))update

更改数据。必要时与where（2.6）搭配使用。

### 2.5 -(LBFMDBMaker*(^)(NSString*tableName))select

查询数据。必要时与where（2.6）搭配使用。查询结果会存储在LBFMDBMaker对象的resultSet属性中。

### 2.6 -(LBFMDBMaker*(^)(NSString*termStr))where

增加条件。需自行写正确的sql语句，例如查age属性为18的人，就听该传入"age = 18"。

### 2.7 -(LBFMDBMaker*(^)(NSString*tableName,NSString*column,NSString*columnType))addColumn

增加键。给表增加一个column。

### 2.8 -(LBFMDBMaker*(^)(NSDictionary*table,NSDictionary<NSString*,NSString*>*relation))dataMove

数据迁移。应用场景：表的键名称有变化或者键数量有变化（键增加可以使用addColumn（2.7），减少时只能用它了）。

### 2.9 -(void)fire:(void(^)(void))handler

执行编辑好的指令集。最后必须要调用这个方法。

# 使用

目前，支持四种数据类型的存储。可在addColumn、appendValueType方法中拓展数据类型。

接下来，通过几个场景，简单的介绍一下使用方法。

### 1.创建“动物学校”数据库

```

[LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:nil];

```

### 2.创建“三年二班”表,并录入两个同学的信息

```

[LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:^(LBFMDBMaker *dbmaker) {
    
    NSDictionary * classTable =
    @{
        @"name":@"三年二班",
        @"properties":
            @{
                @"name":@"string",
                @"age":@"int",
                @"height":@"double",
                @"carnivorous":@"bool"
            }
    };
    
    NSDictionary * student1 =
    @{
        @"name":@"虎子",
        @"age":@6,
        @"height":@118.73,
        @"carnivorous":@YES
    };
    
    NSDictionary * student2 =
    @{
        @"name":@"咩咩",
        @"age":@3,
        @"height":@67,
        @"carnivorous":@NO
    };
    
    [dbmaker
     .createTable(classTable)
     .insert(@"三年二班",student1)
     .insert(@"三年二班",student2) fire:nil];
}];

```

### 3.学校要求同学要把户籍也加上

```

[LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:^(LBFMDBMaker *dbmaker) {
    [dbmaker
     .addColumn(@"三年二班",@"adress",@"string")
     .update(@"三年二班",@"adress",@"东北")
     .where(@"name = '虎子'")
     .update(@"三年二班",@"adress",@"美丽的草原")
     .where(@"name = '咩咩'") fire:nil];
}];

```

### 4.由于老师的粗心，把户籍写成了“adress“。现在要求改正。

```

[LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:^(LBFMDBMaker *dbmaker) {
    NSDictionary * classTable =
    @{
        @"name":@"三年二班",
        @"properties":
            @{
                @"name":@"string",
                @"age":@"int",
                @"height":@"double",
                @"carnivorous":@"bool",
                @"address":@"string"
            }
    };
    
    NSDictionary * relation =
    @{
        @"name":@"name",
        @"age":@"age",
        @"height":@"height",
        @"carnivorous":@"carnivorous",
        @"address":@"adress"  // 有变化的column
    };
    
    [dbmaker
     .dataMove(classTable,relation,2) fire:nil];
}];

```

### 5.统计本班同学

```

[LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:^(LBFMDBMaker *dbmaker) {
    [dbmaker
     .select(@"三年二班") fire:^{
        NSMutableArray * students = [NSMutableArray array];
        FMResultSet * resultSet = dbmaker.resultSet;
        while ([resultSet next]) {
            NSMutableDictionary * student = [NSMutableDictionary dictionary];
            [student setValue:[resultSet stringForColumn:@"name"] forKey:@"name"];
            [student setValue:@([resultSet intForColumn:@"age"]) forKey:@"age"];
            [student setValue:@([resultSet doubleForColumn:@"height"]) forKey:@"height"];
            [student setValue:@([resultSet boolForColumn:@"carnivorous"]) forKey:@"carnivorous"];
            [student setValue:[resultSet stringForColumn:@"address"] forKey:@"address"];
            
            [students addObject:student];
        }
    }];
}];

```

### 6.学校要求分班，把吃素的、吃荤的分开

```

[LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:^(LBFMDBMaker *dbmaker) {
    [dbmaker
     .deleteData(@"三年二班")
     .where(@"carnivorous = 1") fire:nil];
}];

```

通过以上6个场景，可以很清晰的了解本框架基本的操作（增、删、改、查、增加键、数据迁移），具体代码见demo。之后我还会不断完善功能。开发过程中，还需通过控制台日志，来查看指令执行情况。


# 其他

3rd framework: FMDatabase

debug tools:DB Browser for SQLite
