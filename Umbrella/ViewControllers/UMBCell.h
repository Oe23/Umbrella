//
//  UMBCell.h
//  Umbrella
//
//  Created by Oski on 5/21/13.
//  Copyright (c) 2013 Umbrella Corp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UMBCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *weatherIcon;
@property (weak, nonatomic) IBOutlet UILabel *weathercondition;
@property (weak, nonatomic) IBOutlet UILabel *weatherTemp;
@property (weak, nonatomic) IBOutlet UILabel *weatherTime;
@property (weak, nonatomic) IBOutlet UILabel *weatherAmPM;

@end
