 //
//  UMBMainViewController.m
//  Umbrella
//
//  Created by {{YOUR_NAME_HERE}} on 9/12/12.
//  Copyright (c) 2013 {{YOUR_NAME_HERE}}. All rights reserved.
//

#import "UMBMainViewController.h"
#import "UMBFlipsideViewController.h"
#import "UMBCell.h"
#import "WeatherAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>

static NSString *myAPI = @"8aa7ea92c1993fcf";
#define seconds_per_day 86400

@interface UMBMainViewController ()<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
    IBOutlet UITableViewCell *UMBCell;

}

/*!
 @method showSettings:
 @abstract On tap, shows the settings (flipside) screen
 @param sender The button that was tapped
 */
@property WeatherAPIClient *WeatherApi;

@property (weak, nonatomic) IBOutlet UILabel *currentWInd;
@property (weak, nonatomic) IBOutlet UILabel *currentHumidity;
@property (weak, nonatomic) IBOutlet UILabel *currentPrecip;
@property (weak, nonatomic) IBOutlet UILabel *currentConditions;
@property (weak, nonatomic) IBOutlet UILabel *currentTemp;
@property (weak, nonatomic) IBOutlet UILabel *locationFullName;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UITableView *hourlyTemp;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

@property (strong, nonatomic) NSMutableArray *currentTempArray;
@property (strong, nonatomic) NSMutableArray *hourlyArray;
@property (strong, nonatomic) NSMutableArray *day1Array;
@property (strong, nonatomic) NSMutableArray *day2Array;
@property (strong, nonatomic) NSMutableArray *day3Array;

@property (strong, nonatomic) NSMutableDictionary *userSettings;
@property (strong, nonatomic) NSMutableDictionary *currentTempDict;

- (IBAction)showSettings:(id)sender;

@end

@implementation UMBMainViewController


- (void)viewDidLoad
{


    [super viewDidLoad];
    self.backgroundView.image = [UIImage imageNamed:@"detail_header_background"];
    
    [self pullData];//separated out the initial data request to work independently 
    
    //connects to weather singleton, add my my key to url string
    self.WeatherApi = [WeatherAPIClient sharedClient];
    self.WeatherApi.APIKey = myAPI;
    
    //create a string that has the zipcode value from user defaults to call the data method
    NSString *getZipCodeData = [self.userSettings valueForKey:@"zipCode"];
    [self data:getZipCodeData];
   
}

- (void)viewWillAppear:(BOOL)animated
{
    [self pullData];
    NSString *getZipCodeData = [self.userSettings valueForKey:@"zipCode"];
    [self data:getZipCodeData];
    
    
    [self createCurrentConditions:self.currentTempDict];
//    [self updateHourlyForecast];
    [self.hourlyTemp reloadData];
    
    
 
}

- (void)pullData
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"userSettings"]) {
        self.userSettings = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"userSettings"]];
          } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add ZipCode", @"alert")
                                                        message:NSLocalizedString(@"You must add your location in the settings menu", @"alert")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"alert")
                                              otherButtonTitles:NSLocalizedString(@"Open Settings", @"alert"), nil];
        [alert show];
        
    }

}
- (void)data:(NSString*)zipCode
{
    //create mutable copyies of arrays so they won't be nil and throw an error
    self.hourlyArray = [@[] mutableCopy];
    self.currentTempArray = [@[] mutableCopy];
    self.day1Array = [@[] mutableCopy];
    self.day2Array = [@[] mutableCopy];
    self.day3Array = [@[] mutableCopy];
    

    
    
    [self.WeatherApi getForcastAndConditionsForZipCode:zipCode withCompletionBlock:^(BOOL success, NSDictionary *result, NSError *error) {
        //create an alert for the user to let them know the network can't be reached
        if (error) {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Unavailable", @"errorAlert")
                                                                     message:NSLocalizedString(@"Check Network Connection", @"errorAlert")
                                                                    delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"OK", @"errorAlert")
                                                           otherButtonTitles: nil];
                [errorAlert show];
                return ;
            }
         //create array for detail current weather view
         self.currentTempDict =[[NSMutableDictionary alloc] initWithDictionary:[result valueForKey:@"current_observation"]];
            [self createCurrentConditions:self.currentTempDict];
        
        //iterate through the hourly forecast json dict toorganize the data by weekday but into array to populate table data by appropriate headers
        NSMutableArray *jsonResultArray = [result valueForKey:@"hourly_forecast"];
        for (NSDictionary *resultdictionary in jsonResultArray)
        {
            NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
            [formattedDate setDateFormat:@"EEEE"]; // prints weekdays
            NSDate *day1 = [NSDate date]; //today's weekday
            NSDate *day2 = [NSDate dateWithTimeIntervalSinceNow:seconds_per_day]; //calculate the seconds in the day to get to next day
            
            NSString *jsonResultString = [resultdictionary valueForKeyPath:@"FCTTIME.weekday_name"];
            NSLog(@"this is the days %@", jsonResultString);
            if ([jsonResultString isEqualToString:[formattedDate stringFromDate:day1]]){
                [self.day1Array addObject:resultdictionary];
            } else if ([jsonResultString isEqualToString:[formattedDate stringFromDate:day2]]) {
                [self.day2Array addObject:resultdictionary];
            } else {
                [self.day3Array addObject:resultdictionary];
            }
        }
            //stop the activity spinner once data is downloaded and bring in the tableview
            [self.activityIndicator stopAnimating];
            [UIView animateWithDuration:1.0 animations:^{
                self.activityIndicator.alpha = 0.0;
                self.hourlyTemp.alpha = 1.0;
            }];
     
            //refresh table views
            [self updateHourlyForecast];
            [self.hourlyTemp reloadData];
                }];
}


- (void)createCurrentConditions:(NSDictionary*)currentTempDict
{
    //get location/upate UI
    self.locationFullName.text = [NSString stringWithFormat:@"%@", [currentTempDict  valueForKeyPath:@"display_location.full"]];

    //string to denote user preference of US or Metric units from the user preference settings
    NSString *userPref;
  
    //Get Precipiation, set english or metric pref bacsed on userdefaults, round to the nearest tenth,
    userPref = ([[self.userSettings objectForKey:@"userSettings"] isEqualToString:@"32"] ? @"precip_today_in" : @"precip_today_metric");
    NSString *unit = ([[self.userSettings objectForKey:@"userSettings"] isEqualToString:@"32"] ? @"in" : @"cm");
    double precipDouble = [[currentTempDict valueForKeyPath:userPref]doubleValue];
    NSString *roundedNumber = [NSString stringWithFormat:@"%.*f", fmod(round(precipDouble * 100), 100) ? 1 : 0, precipDouble];
    if (([roundedNumber isEqualToString:@"0"]) || ([roundedNumber floatValue] < 0.0f))
    {
        roundedNumber = @"0.0";
    }
    self.currentPrecip.text = [NSString stringWithFormat:@"%@%@", roundedNumber, unit];
   
    //get humidity
    self.currentHumidity.text = [currentTempDict valueForKey:@"relative_humidity"];
    
    //get the userdefault preference, find the correct measurement, keep UI updated
    NSString *windSpeedUnit = ([[self.userSettings objectForKey:@"tempScalePref"] isEqualToString:@"32"] ? @"MPH" : @"KPH");
    userPref = ([[self.userSettings objectForKey:@"tempScalePref"] isEqualToString:@"32"] ? @"wind_mph" : @"wind_kph");
    self.currentWInd.text = [NSString stringWithFormat:@"%@%@", [currentTempDict valueForKeyPath:userPref], windSpeedUnit];
    
    //choose the userdefault preferenece, get the current temp, turn it into an integer, add the degree symbol
    userPref = ([[self.userSettings objectForKey:@"tempScalePref"] isEqualToString:@"32"] ? @"temp_f" : @"temp_c");
    int tempInt = [[currentTempDict valueForKeyPath:userPref] intValue]; //turn temp string to a int
    self.currentTemp.text = [NSString stringWithFormat:@"%d%@", tempInt, @"\u00B0"];

    //get current condition
    self.currentConditions.text = [currentTempDict valueForKey:@"weather"];
    
}

//add array of dictionary in order based on the forecast weekday
- (void)updateHourlyForecast
{
    [self.hourlyArray addObject:self.day1Array];
    [self.hourlyArray addObject:self.day2Array];
    [self.hourlyArray addObject:self.day3Array];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View

- (IBAction)showSettings:(id)sender
{
    UMBFlipsideViewController *controller = [[UMBFlipsideViewController alloc] initWithNibName:@"UMBFlipsideViewController" bundle:nil];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:(sender) ? YES : NO completion:nil];
}

//once page in is reloaded from settings view, reset the data based on the new user default, animate the activity indicateor
- (void)flipsideViewControllerDidFinish:(UMBFlipsideViewController *)controller
{
    [self pullData];
    [self.activityIndicator startAnimating];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [UIView animateWithDuration:1.0 animations:^{
        self.activityIndicator.alpha = 1.0;
     self.hourlyTemp.alpha = 0.0;
        
    [self dismissViewControllerAnimated:YES completion:nil];
        
     }];


}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.hourlyArray count];
              //number of sections organize by days of arrays that match the current da plus the following two days
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.hourlyArray objectAtIndex:section] count];
    //row are created based the amount data of reported forecast hours
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"UMBCell";
    //custom cell with identifier
    UMBCell *cell = (UMBCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) //if cell is nil, check the bundle for the custom cell nib at the appropriate index
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"UMBCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
        cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dashed_line_pattern.png"]];
    if (self.hourlyArray) {

        
        //cell weather condition
            cell.weathercondition.text = [[[self.hourlyArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKeyPath:@"condition"];
        
        
        //cell temp, choose user default and set it
        NSString *userSettings = ([[self.userSettings objectForKey:@"tempScalePref"]isEqualToString:@"32"] ? @"temp.english" : @"temp.metric");
        cell.weatherTemp.text = [NSString stringWithFormat:@"%@%@", [[[self.hourlyArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKeyPath:userSettings], @"\u00B0"];
        
        //cell time
        NSString *hour = [[[self.hourlyArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKeyPath:@"FCTTIME.civil"];
       // NSString *min = [[[self.hourlyArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKeyPath:@"FCTTIME.min"];
        cell.weatherTime.text = [NSString stringWithFormat:@"%@", hour];
        
        //cell amPM--add the amp/pm to UI
            cell.weatherAmPM.text = [[[self.hourlyArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] valueForKeyPath:@"FCTTIME.ampm"];
        //cell icon
        NSString *iconString =[NSString stringWithString:[[[self.hourlyArray objectAtIndex:indexPath.section]objectAtIndex:indexPath.row]valueForKeyPath:@"icon_url"]];
        
        //change icon set to icon set 9
        NSString *icon9String = [iconString stringByReplacingOccurrencesOfString:@"/k/" withString:@"/i/"];
        NSURL *iconURL = [NSURL URLWithString:icon9String];
        NSData *iconData = [NSData dataWithContentsOfURL:iconURL];
        UIImage *icon = [UIImage imageWithData:iconData];
        
        
        CGSize resize = CGSizeMake(20, 20);
        UIGraphicsBeginImageContext(resize);
        [icon drawInRect:CGRectMake(0, 0, resize.width, resize.height)];
        UIImage *newIcon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cell.weatherIcon.image = newIcon;
        
        //create border around weatherIcon
        cell.weatherIcon.layer.masksToBounds = YES;
        cell.weatherIcon.layer.borderColor = [UIColor blackColor].CGColor;
        cell.weatherIcon.layer.borderWidth = 1;
        
        
        //create dashed border between cells
        self.hourlyTemp.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
        self.hourlyTemp.separatorStyle = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dashed_line_pattern"]];
        
    }
    return cell;
    
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //set to nil if the count is equal to or less than zero to keep array inbounds.
    if ([[self.hourlyArray objectAtIndex:section] count] <=0) {
        return nil;
    }
    //set label text header
    NSString *sectionTitle =[NSString stringWithFormat:@"%@",[[[self.hourlyArray objectAtIndex:section] objectAtIndex:0] valueForKeyPath:@"FCTTIME.weekday_name"]];
    //create label, size, color it, set the text
    UILabel *label = [[UILabel alloc]init];
    label.frame = CGRectMake(15, 0, 305, 22);
    label.textColor = [UIColor whiteColor];
    label.text = sectionTitle;
    label.backgroundColor = [UIColor clearColor];
    label.layer.borderColor = [[UIColor clearColor]CGColor];
    
    //programatically create header view and add label as a subview, add the backdground image to the header
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 22)];
    UIImageView *headerbackground = [[UIImageView alloc]initWithFrame:headerView.frame];
    headerbackground.contentMode = UIViewContentModeScaleAspectFill;
    headerbackground.image = [UIImage imageNamed:@"section_header_background.png"];
    [headerView addSubview:headerbackground];
    [headerView sendSubviewToBack:headerbackground];
    [headerView addSubview:label];
    
    //don't show border
    headerView.layer.borderColor = [[UIColor clearColor]CGColor];
    
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return  25;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        
    
            // if settings button is pressed go to that view 
        UMBFlipsideViewController *controller = [[UMBFlipsideViewController alloc] initWithNibName:@"UMBFlipsideViewController" bundle:nil];

            controller.delegate = self;
            controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:controller animated:YES  completion:nil];

    }
}


@end
