//
//  UMBFlipsideViewController.m
//  Umbrella
//
//  Created by {{YOUR_NAME_HERE}} on 9/12/12.
//  Copyright (c) 2013 {{YOUR_NAME_HERE}}. All rights reserved.
//

#import "UMBFlipsideViewController.h"

@interface UMBFlipsideViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (weak, nonatomic) IBOutlet UIImageView *gtitle;
@property (weak, nonatomic) IBOutlet UITextField *zipcodeTextBox;
@property (weak, nonatomic) IBOutlet UIButton *fahrenheitButton;
@property (weak, nonatomic) IBOutlet UIButton *celsiusButton;
@property (weak, nonatomic) IBOutlet UIButton *weatherButton;
@property (weak, nonatomic) IBOutlet UIView *formView;
@property (weak, nonatomic) IBOutlet UIImageView *header1;
@property (weak, nonatomic) IBOutlet UIImageView *header2;
@property (weak, nonatomic) IBOutlet UIImageView *dashHeader;
@property (weak, nonatomic) IBOutlet UIImageView *dashHeader2;
@property (weak, nonatomic) IBOutlet UIImageView *dashHeader3;
@property (weak, nonatomic) IBOutlet UIImageView *dashHeader4;
@property (weak, nonatomic) IBOutlet UIImageView *dashHeader5;


@property (strong, nonatomic)  NSMutableDictionary *userSettings;
@property (strong, nonatomic) NSUserDefaults *defaults;

@end

@implementation UMBFlipsideViewController
//
//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        
//    }
//    return self;
//}


- (void)viewDidLoad
{
  
  [super viewDidLoad];
    [self loadDefaultPreferences];
    
    
    //load all images/outlets
    self.gtitle.image = [UIImage imageNamed:@"umbrellaTitle.png"];
    self.background.image = [UIImage imageNamed:@"Default.png"];
    self.formView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"settingsFormBackground.png"]];
    self.header1.image = [UIImage imageNamed:@"section_header_background.png"];
    self.header2.image = [UIImage imageNamed:@"section_header_background.png"];
    self.dashHeader.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dashed_line_pattern.png"]];
    self.dashHeader2.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dashed_line_pattern.png"]];
    self.dashHeader3.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dashed_line_pattern.png"]];
    self.dashHeader4.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dashed_line_pattern.png"]];
    self.dashHeader5.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dashed_line_pattern.png"]];
     
        
    //customize Weather button
    self.weatherButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, (self.weatherButton.titleLabel.frame.size.width + 10.0f), 5.0f, 0.0f);
    [self.weatherButton setImage:[UIImage imageNamed:@"submit_icon.png"] forState:UIControlStateNormal];
    
    UIImage *backgroundImage = [[UIImage imageNamed:@"button_background.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(15.0f, 15.0f, 15.0f, 15.0f) resizingMode:UIImageResizingModeStretch];
    [self.weatherButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [self.weatherButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, -20.0f, 6.0f, 0.0f)];
    
    [self enableDoneButton];

}


-(void)loadDefaultPreferences
{
    //set up and store user settings in userdefaults
    ;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"userSettings"]) {
        self.userSettings = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"userSettings"]];
    } else {
        self.userSettings =[ @{
                            @"zipCode"      : @"60649",
                            @"tempScalePref": @"32"} mutableCopy]; // 32f is the equiv of 0C
    }
    
    self.zipcodeTextBox.text = [self.userSettings objectForKey:@"zipCode"];
    
    if ([[self.userSettings objectForKey:@"tempScalePref"] isEqualToString:@"32"]) {
        
        [self.fahrenheitButton setBackgroundImage:[UIImage imageNamed:@"checkmark_on.png"] forState:UIControlStateNormal];
        [self.celsiusButton setBackgroundImage:[UIImage imageNamed:@"checkmark_off.png"] forState:UIControlStateNormal];
    } else {
        [self.fahrenheitButton setBackgroundImage:[UIImage imageNamed:@"checkmark_off.png"] forState:UIControlStateNormal];
        [self.celsiusButton setBackgroundImage:[UIImage imageNamed:@"checkmark_on.png"] forState:UIControlStateNormal];
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark- Textfield Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{    ///user can't enter more than 5 characters--the 6th character will dismiss the keyboard
    if ([self.zipcodeTextBox.text length] == 5 && ![string isEqualToString:@""]) {
        
        [self.zipcodeTextBox resignFirstResponder];
        return NO;
    } else {
        return YES;
    }
}
#pragma mark - Actions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.zipcodeTextBox resignFirstResponder];
}

- (void)enableDoneButton
{    if (self.zipcodeTextBox.text) {
    self.weatherButton.enabled = YES;
    }
}
- (IBAction)tempScaleButtoTapped:(UIButton*)sender {
    
    //change background image of button pressed
    [sender setBackgroundImage:[UIImage imageNamed:@"checkmark_on"] forState:UIControlStateNormal];
    
    //change background of buttons when selected
    if (sender.tag == 32) {
        [self.celsiusButton setBackgroundImage:[UIImage imageNamed:@"checkmark_off.png"] forState:UIControlStateNormal];
    } else {
        [self.fahrenheitButton setBackgroundImage:[UIImage imageNamed:@"checkmark_off.png"] forState:UIControlStateNormal];
    }
    //update user settings with temperature scale preference
    [self.userSettings setObject:[NSString stringWithFormat:@"%d", sender.tag] forKey:@"tempScalePref"];
    
    [self enableDoneButton];
}
- (IBAction)done:(id)sender
{
    // save zip and temperature scale to NSUserDefaults
    [self.userSettings setObject:self.zipcodeTextBox.text forKey:@"zipCode"];
    [[NSUserDefaults standardUserDefaults] setObject:self.userSettings forKey:@"userSettings"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"user default is %@",self.userSettings);
    
    [self.delegate flipsideViewControllerDidFinish:self];
    
}

@end
