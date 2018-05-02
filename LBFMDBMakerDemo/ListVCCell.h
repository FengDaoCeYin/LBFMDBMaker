//
//  ListVCCell.h
//  LBFMDBMakerDemo
//
//  Created by 刘博 on 2018/4/28.
//  Copyright © 2018年 刘博. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListVCCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *IDLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UILabel *weightLabel;
@property(nonatomic,copy)NSDictionary* cellData;
@end
