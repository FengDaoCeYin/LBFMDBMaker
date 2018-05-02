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
    _IDLabel.text = cellData[@"ID"];
    _nameLabel.text = cellData[@"name"];
    _ageLabel.text = cellData[@"age"];
    _weightLabel.text = cellData[@"weight"];
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
