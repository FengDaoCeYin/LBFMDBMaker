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
{
    LBFMDBServeCenter * center;
}
@property (weak, nonatomic) IBOutlet UITextField *oNameTF;
@property (weak, nonatomic) IBOutlet UITextField *nNameTF;

@end

@implementation ViewController

- (IBAction)inputData:(id)sender {
    LBFMDBServeCenter * center = [LBFMDBServeCenter sharedFMDBCenter];
    [center operateDBWithDBName:@"3年级五班" lb_makeSQLCommon:^(LBFMDBMaker *maker) {
        [maker
        .Table(@"t_person",@[@"name",@"age",@"weight"],@[@0,@1,@2])
        .Insert(@"t_person",@[@"name",@"age",@"weight"],@[@"小鸡",@18,@73.3])
        .Insert(@"t_person",@[@"name",@"age",@"weight"],@[@"老牛",@19,@88.6])
        .Insert(@"t_person",@[@"name",@"age",@"weight"],@[@"大鸭",@16,@50.6]) fire:nil];
        
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
            ListViewController * listVC = [[ListViewController alloc]init];
            listVC.persons = persons;
            [self.navigationController pushViewController:listVC animated:YES];
        }];
    }];
}

- (IBAction)updateData:(id)sender {
    [center operateDBWithDBName:@"3年级五班" lb_makeSQLCommon:^(LBFMDBMaker *maker) {
        [maker
         .Table(@"t_person",@[@"name",@"age",@"weight"],@[@0,@1,@2])
         .Update(@"t_person",@"name",_nNameTF.text)
         .Where([NSString stringWithFormat:@"name = '%@'",_oNameTF.text])
         .Select(@"t_person") fire:^{
            
            FMResultSet * set = maker.resultSet;
            NSMutableArray * persons = [NSMutableArray array];
            while ([set next]) {
                int ID = [set intForColumnIndex:0];
                NSString * name = [set stringForColumnIndex:1];
                int age = [set intForColumnIndex:2];
                double weight = [set doubleForColumnIndex:3];
                
                NSMutableDictionary * person = [NSMutableDictionary dictionary];
                [person setValue:[NSString stringWithFormat:@"%d",ID] forKey:@"id"];
                [person setValue:name forKey:@"name"];
                [person setValue:[NSString stringWithFormat:@"%d",age] forKey:@"age"];
                [person setValue:[NSString stringWithFormat:@"%.2f",weight] forKey:@"weight"];
                
                [persons addObject:person];
            }
            ListViewController * listVC = [[ListViewController alloc]init];
            listVC.persons = persons;
            [self.navigationController pushViewController:listVC animated:YES];
        }];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    center = [LBFMDBServeCenter sharedFMDBCenter];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
