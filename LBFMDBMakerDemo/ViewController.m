//
//  ViewController.m
//  LBFMDBMakerDemo
//
//  Created by 刘博 on 2018/4/28.
//  Copyright © 2018年 刘博. All rights reserved.
//

#import "ViewController.h"
#import "ListViewController.h"
#import "LBFMDBServeCenter.h"

@interface ViewController ()

@end

@implementation ViewController

// 1.创建“动物学校”数据库
-(void)createDB {
    [LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:nil];
}

// 2.创建“三年二班”表,并录入两个同学的信息
-(void)createClass {
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
}

// 3.学校要求同学要把户籍也加上
-(void)addAdress {
    [LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:^(LBFMDBMaker *dbmaker) {
        [dbmaker
         .addColumn(@"三年二班",@"adress",@"string")
         .update(@"三年二班",@"adress",@"东北")
         .where(@"name = '虎子'")
         .update(@"三年二班",@"adress",@"美丽的草原")
         .where(@"name = '咩咩'") fire:nil];
    }];
}

// 4.由于老师的粗心，把户籍写成了“adress“。现在要求改正。
-(void)changeColumn {
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
}

// 5.统计本班同学
-(void)census {
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
            
            ListViewController * listVC = [[ListViewController alloc] init];
            listVC.dataArr = students;
            [self.navigationController pushViewController:listVC animated:YES];
        }];
    }];
}

// 6.学校要求分班，把吃素的、吃荤的分开
-(void)deleteData {
    [LBFMDBServeCenter.sharedFMDBCenter operateDBWithName:@"动物学校" commonMaker:^(LBFMDBMaker *dbmaker) {
        [dbmaker
         .deleteData(@"三年二班")
         .where(@"carnivorous = 1") fire:nil];
    }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self changeColumn];
    
    NSLog(@"%@",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
