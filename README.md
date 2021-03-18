### 前言

客户端数据库操作长久以来一直是程序猿们的痛点，写sql语句更是恶心。稍有不慎，语句哪个符号忘了加，或是大小写弄错了等等，就会出问题，而且排查起来多有不便。于是，数据库链式操作就诞生了~！

### 类介绍

LBFMDBServeCenter是入口单例类。

LBFMDBMaker是数据库操作处理类。

### 使用

如下图。首先创建了”3年五班“数据库。然后用改数据库的操作对象mark添加了"t_person"表，这个表有三个属性"name"、"age"、"weight"，分别是字符型、整型、double。然后，像表中插入小鸡同学的相关信息。最后通过fire函数，执行以上所有的数据库操作。

```

LBFMDBServeCenter * center = [LBFMDBServeCenter sharedFMDBCenter];

[center operateDBWithDBName:@"3年级五班" lb_makeSQLCommon:^(LBFMDBMaker *maker) {

[maker

.Table(@"t_person",@[@"name",@"age",@"weight"],@[@0,@1,@2])

.Insert(@"t_person",@[@"name",@"age",@"weight"],@[@"小鸡",@18,@73.3])

fire:nil];

}];

```

接着，我们可以查询一下这个表。

```

[maker.Select(@"t_person") fire:^{

FMResultSet * set = maker.resultSet;

NSMutableArray * persons = [NSMutableArray array];

while ([set next]) {

int ID = [set intForColumnIndex:0];

NSString * name = [set stringForColumnIndex:1];

int age = [set intForColumnIndex:2];

double weight = [set doubleForColumnIndex:3];

NSMutableDictionary * person = [NSMutableDictionary dictionary];

[person setValue:[NSString stringWithFormat:@"%d",ID] forKey:@"ID"];

[person setValue:name forKey:@"name"];

[person setValue:[NSString stringWithFormat:@"%d",age] forKey:@"age"];

[person setValue:[NSString stringWithFormat:@"%.2f",weight] forKey:@"weight"];

[persons addObject:person];

}

}];

```

以上就是简单地介绍，具体用法请参考代码。
