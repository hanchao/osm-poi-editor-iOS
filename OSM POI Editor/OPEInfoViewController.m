//
//  OPEInfoViewController.m
//  OSM POI Editor
//
//  Created by David Chiles on 2/15/12.
//  Copyright (c) 2011 David Chiles. All rights reserved.
//
//  This file is part of POI+.
//
//  POI+ is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  POI+ is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with POI+.  If not, see <http://www.gnu.org/licenses/>.

#import "OPEInfoViewController.h"
#import "OPEOpenMapQuestAerialTileSource.h"
#import "OPEOpenStreetMapSource.h"
#import "OPEBingTileSource.h"
#import "OPEAPIConstants.h"


@implementation OPEInfoViewController

@synthesize delegate;
@synthesize currentNumber;
@synthesize settingsTableView;
@synthesize attributionString;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    settingsTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [settingsTableView setDataSource:self];
    [settingsTableView setDelegate:self];
    settingsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if ([settings objectForKey:@"tileSourceNumber"]) {
        currentNumber = [[settings objectForKey:@"tileSourceNumber"] intValue];
    }
    else {
        currentNumber = 0;
    }
    
    [self.view addSubview:settingsTableView];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)doneButtonPressed:(id)sender
{
    GTMOAuthAuthentication *auth = [self osmAuth];
    BOOL didAuth = NO;
    BOOL canAuth = NO;
    if (auth) {
        didAuth = [GTMOAuthViewControllerTouch authorizeFromKeychainForName:@"OSMPOIEditor"
                                                                  authentication:auth];
        canAuth = [auth canAuthorize];
    }
    NSLog(@"didAuth %d",didAuth);
    NSLog(@"canAuth %d",canAuth);
}

- (void)viewController:(GTMOAuthViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuthAuthentication *)auth
                 error:(NSError *)error {
    [settingsTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        NSLog(@"Authentication error: %@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"];// kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            NSString *str = [[NSString alloc] initWithData:responseData
                                                   encoding:NSUTF8StringEncoding];
            NSLog(@"%@", str);
        }
        
        //[self setAuthentication:nil];
    } else {
        // Authentication succeeded
        //
        // At this point, we either use the authentication object to explicitly
        // authorize requests, like
        //
        //   [auth authorizeRequest:myNSURLMutableRequest]
        //
        // or store the authentication object into a GTM service object like
        //
        //   [[self contactService] setAuthorizer:auth];
        
        // save the authentication object
        //[self setAuthentication:auth];
        
        // Just to prove we're signed in, we'll attempt an authenticated fetch for the
        // signed-in user
        //[self doAnAuthenticatedAPIFetch];
    }
    
    //[self updateUI];
}


- (GTMOAuthAuthentication *)osmAuth {
    NSString *myConsumerKey = osmConsumerKey; //@"pJbuoc7SnpLG5DjVcvlmDtSZmugSDWMHHxr17wL3";    // pre-registered with service
    NSString *myConsumerSecret = osmConsumerSecret; //@"q5qdc9DvnZllHtoUNvZeI7iLuBtp1HebShbCE9Y1"; // pre-assigned by service
    
    GTMOAuthAuthentication *auth;
    auth = [[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
                                                       consumerKey:myConsumerKey
                                                        privateKey:myConsumerSecret];
    
    // setting the service name lets us inspect the auth object later to know
    // what service it is for
    auth.serviceProvider = @"OSMPOIEditor";
    
    return auth;
}

- (void)signInToOSM {
    
    NSURL *requestURL = [NSURL URLWithString:@"http://www.openstreetmap.org/oauth/request_token"];
    NSURL *accessURL = [NSURL URLWithString:@"http://www.openstreetmap.org/oauth/access_token"];
    NSURL *authorizeURL = [NSURL URLWithString:@"http://www.openstreetmap.org/oauth/authorize"];
    NSString *scope = @"http://api.openstreetmap.org/";
    
    GTMOAuthAuthentication *auth = [self osmAuth];
    if (auth == nil) {
        // perhaps display something friendlier in the UI?
        NSLog(@"A valid consumer key and consumer secret are required for signing in to OSM");
    }
    
    // set the callback URL to which the site should redirect, and for which
    // the OAuth controller should look to determine when sign-in has
    // finished or been canceled
    //
    // This URL does not need to be for an actual web page
    [auth setCallback:@"http://www.google.com/OAuthCallback"];
    
    // Display the autentication view
    GTMOAuthViewControllerTouch * viewController = [[GTMOAuthViewControllerTouch alloc] initWithScope:scope
                                                               language:nil
                                                        requestTokenURL:requestURL
                                                      authorizeTokenURL:authorizeURL
                                                         accessTokenURL:accessURL
                                                         authentication:auth
                                                         appServiceName:@"OSMPOIEditor"
                                                               delegate:self
                                                       finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    [[self navigationController] pushViewController:viewController
                                           animated:YES];
}

- (void) signOutOfOSM
{
    [GTMOAuthViewControllerTouch removeParamsFromKeychainForName:@"OSMPOIEditor"];
    [settingsTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}
#pragma - TableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 3;
    }
    else {
        return 1;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Tile Source";
    }
    else {
        return @"";
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(section == 0 && self.attributionString)
    {
        return self.attributionString;
    }
    return @"";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    static NSString * tileIdentifier = @"Cell";
    static NSString * buttonIdentifier = @"Cell1";
    static NSString * aboutIdentifier = @"Cell2";
    if (indexPath.section == 0) {
        
        //cell = [tableView dequeueReusableCellWithIdentifier:tileIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tileIdentifier];
        }
        
        if (indexPath.row == 0){
            cell.textLabel.text = @"Bing Aerial";
        }
        else if (indexPath.row == 1){
            cell.textLabel.text = @"OpenMapquest Aerial";
        }
        else if (indexPath.row == 2) {
            cell.textLabel.text = @"OSM Default";
        }
        
        if (indexPath.row == currentNumber) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
    
    }
    else if (indexPath.section == 1)
    {
        //cell = [tableView dequeueReusableCellWithIdentifier:buttonIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonIdentifier];
        }
        
        if(![self loggedIn])
        {
            cell.textLabel.text = @"Login to OpenStreetMap";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else
            cell.textLabel.text = @"Logout of OpenStreetMap";
        
    }
    else if (indexPath.section == 2)
    {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:aboutIdentifier];
        }
        cell.textLabel.text = @"About POI+";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0) {
        UITableViewCell * cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentNumber inSection:0]]; //Switch check marks
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        currentNumber = indexPath.row;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        id <RMTileSource> newTileSource = [OPEInfoViewController getTileSourceFromNumber:indexPath.row];
        
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        [settings setObject:[NSNumber numberWithInt:indexPath.row] forKey:@"tileSourceNumber"];
        [settings synchronize];
        [delegate setTileSource:newTileSource at:indexPath.row ];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else if (indexPath.section == 1)
    {
        if(![self loggedIn])
        {
            [self signInToOSM];
        }
        else
            [self signOutOfOSM];
        
    }
    else if (indexPath.section == 2) {
        [self infoButtonPressed:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma - TileSource

-(void)changeTileSourceTo:(NSString *) newSoureceName
{
    id <RMTileSource> newTileSource = nil;
    newTileSource = [[OPEBingTileSource alloc] init];
    
    //[delegate setTileSource:newTileSource a];
    
}

#pragma mark - View lifecycle

-(BOOL)loggedIn
{
    GTMOAuthAuthentication *auth = [self osmAuth];
    BOOL didAuth= NO;
    BOOL canAuth= NO;
    BOOL hasAuth= NO;
    if (auth) {
        didAuth = [GTMOAuthViewControllerTouch authorizeFromKeychainForName:@"OSMPOIEditor" authentication:auth];
        canAuth = [auth canAuthorize];
        hasAuth = [auth hasAccessToken];
    }
    
    if (didAuth && canAuth && hasAuth) {
        NSLog(@"All three true");
        
        return YES;
    }
    else
    {
        NSLog(@"did: %@ can: %@ has: %@",(didAuth ? @"YES" : @"NO"),(canAuth ? @"YES" : @"NO"),(hasAuth ? @"YES" : @"NO"));
        return NO;
    }
    
}

-(void)infoButtonPressed:(id)sender
{
    OPECreditViewController * view = [[OPECreditViewController alloc] init];
    //view.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    //[self presentModalViewController:view animated:YES];
    view.title = @"About";
    [self.navigationController pushViewController:view animated:YES];
}

+ (id)getTileSourceFromNumber:(int) num
{
    if (num == 1) {
        return [[OPEOpenMapQuestAerialTileSource alloc] init];
    }
    else if (num == 2) {
        return [[OPEOpenStreetMapSource alloc] init];
    }
    else{
        return [[OPEBingTileSource alloc] initWithMapsKey:bingMapsKey];
    }
    
    
    return nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [settingsTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
