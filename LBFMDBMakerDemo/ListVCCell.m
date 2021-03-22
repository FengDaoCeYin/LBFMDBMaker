//
//  ListVCCell.m
//  LBFMDBMakerDemo
//
//  Created by 刘博 on 2018/4/28.
//  Copyright © 2018年 刘博. All rights reserved.
//

#import "ListVCCell.h"

@implementation ListVCCell

-(void)setCellData:(NSDictionary *)cellData
{
    _cellData = cellData;
    _IDLabel.text = [NSString stringWithFormat:@"姓名:%@ 年龄:%d 身高:%fcm 吃素:%d 地址:%@",_cellData[@"name"],[_cellData[@"age"] intValue],[_cellData[@"height"] doubleValue],![_cellData[@"carnivorous"] boolValue],_cellData[@"address"]];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
