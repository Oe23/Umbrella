//
//  UMBCell.m
//  Umbrella
//
//  Created by Oski on 5/21/13.
//  Copyright (c) 2013 Umbrella Corp. All rights reserved.
//

#import "UMBCell.h"

@implementation UMBCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
