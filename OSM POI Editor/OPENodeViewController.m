//
//  OPENodeViewController.m
//  OSM POI Editor
//
//  Created by David Chiles on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OPENodeViewController.h"
#import "OPETagInterpreter.h"
#import "OPETextEdit.h"
#import "OPECategoryViewController.h"
#import "OPEOSMData.h"
#import "OPEInfoViewController.h"



@implementation OPENodeViewController

@synthesize node, theNewNode, type;
@synthesize tableView;
@synthesize catAndType;
@synthesize deleteButton, saveButton;
@synthesize delegate;
@synthesize nodeIsEdited;
@synthesize HUD;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    nodeIsEdited = NO;
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle: @"Save" style: UIBarButtonItemStyleBordered target: self action: @selector(saveButtonPressed)];
    
    [[self navigationItem] setRightBarButtonItem:saveButton];
    
    
    deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [self.deleteButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"]
                                           stretchableImageWithLeftCapWidth:8.0f
                                           topCapHeight:0.0f]
                                 forState:UIControlStateNormal];
    
    [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deleteButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.deleteButton.titleLabel.shadowColor = [UIColor lightGrayColor];
    self.deleteButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    //self.deleteButton.frame = CGRectMake(0, 0, 300, 44);
    [self.deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    
    theNewNode = [[OPENode alloc] initWithNode:node];
    [self checkSaveButton];
    
    
    tagInterpreter = [OPETagInterpreter sharedInstance];
    
    NSLog(@"Tags: %@",theNewNode.tags);
    //NSLog(@"new Category and Type: %@",[tagInterpreter getCategoryandType:theNewNode]);
    catAndType = [[NSArray alloc] initWithObjects:[tagInterpreter getCategory:theNewNode],[tagInterpreter getType:theNewNode], nil];
    //osmKeyValue =  [[NSDictionary alloc] initWithDictionary: [tagInterpreter getPrimaryKeyValue:theNewNode]];
    
    self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.HUD.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadComplete:) name:@"uploadComplete" object:nil];
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if(theNewNode.ident<0)
    {
        return 3;
    }
    else {
        return 4;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 1)
        return 2;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return @"Name";
	}
	else if (section == 1) {
		return @"Category";
	}
    else if (section == 2){
        return @"Note";
    }
	else if (section == 3) {
		return @""; //Delete Button Header
	}
	else {
		return @"Subtitle Style";
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier1 = @"Cell_Section_1";
    NSString *CellIdentifier2 = @"Cell_Section_2";
    NSString *CellIdentifier3 = @"Cell_Section_3";
    
    NSArray * catAndTypeName = [[NSArray alloc] initWithObjects:@"Category",@"Type", nil];

    
    
    UITableViewCell *cell;
	if (indexPath.section == 0) {
		cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
		}
        cell.textLabel.text = [theNewNode.tags objectForKey:@"name"];
        cell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;

	}
	else if (indexPath.section == 1) {
		cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier2];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier2];
        }
        cell.textLabel.text = [catAndTypeName objectAtIndex:indexPath.row];
        cell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;
        if ([catAndType count]==2) {
            cell.detailTextLabel.text = [catAndType objectAtIndex:indexPath.row];
        }
        else
        {
            cell.detailTextLabel.text =@"";
        }
        
        
        
        //cell.detailTextLabel.text = [NSString stringWithFormat:@"%d",indexPath.row];
	}
    else if (indexPath.section == 2)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
		}
        cell.textLabel.text = [theNewNode.tags objectForKey:@"note"];
        cell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;
        
    }
    else if (indexPath.section == 3) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier3];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier3];
        }
        
        deleteButton.frame = cell.contentView.bounds;
        NSLog(@"bounds: %f",cell.contentView.bounds.size.width);
        NSLog(@"button: %f",deleteButton.frame.size.width);
        deleteButton.frame = CGRectMake(deleteButton.frame.origin.x, deleteButton.frame.origin.y, 300.0f, deleteButton.frame.size.height);
        
        [cell.contentView addSubview:deleteButton];
    }
    
	
	// Configure the cell...
	//cell.textLabel.text = @"Text Label";
	//cell.detailTextLabel.text = @"Detail Text Label";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        OPETextEdit * viewer = [[OPETextEdit alloc] initWithNibName:@"OPETextEdit" bundle:nil];
        
        viewer.title = @"Name";
        viewer.osmValue = [theNewNode.tags objectForKey:@"name"];
        viewer.osmKey = @"name";
        [viewer setDelegate:self];
        
        [self.navigationController pushViewController:viewer animated:YES];
    }
    else if(indexPath.section == 1)
    {
        
        if(indexPath.row == 1)
        {
            if ([catAndType count]==2) 
            {
                OPETypeViewController * viewer = [[OPETypeViewController alloc] initWithNibName:@"OPETypeViewController" bundle:[NSBundle mainBundle]];
                viewer.title = @"Type";
                
                viewer.category = [catAndType objectAtIndex:0];
                [viewer setDelegate:self];
                NSLog(@"category previous: %@",viewer.category);
                
                [self.navigationController pushViewController:viewer animated:YES];
            }
            else {
                OPECategoryViewController * viewer = [[OPECategoryViewController alloc] initWithNibName:@"OPECategoryViewController" bundle:[NSBundle mainBundle]];
                viewer.title = @"Category";
                [viewer setDelegate:self];
                
                [self.navigationController pushViewController:viewer animated:YES];
            }
            
            
        }
        else
        {
            OPECategoryViewController * viewer = [[OPECategoryViewController alloc] initWithNibName:@"OPECategoryViewController" bundle:[NSBundle mainBundle]];
            viewer.title = @"Category";
            [viewer setDelegate:self];
            
            [self.navigationController pushViewController:viewer animated:YES];
        }
    }
    else if (indexPath.section == 2)
    {
        OPETextEdit * viewer = [[OPETextEdit alloc] initWithNibName:@"OPETextEdit" bundle:nil];
        
        viewer.title = @"Note";
        viewer.osmValue = [theNewNode.tags objectForKey:@"note"];
        viewer.osmKey = @"note";
        [viewer setDelegate:self];
        
        [self.navigationController pushViewController:viewer animated:YES];
    }
}
-(void) showOauthError
{
    if (HUD)
    {
        [HUD hide:YES];
    }
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"OAuth Error"
                                                      message:@"You need to login to OpenStreetMap"
                                                     delegate:self
                                            cancelButtonTitle:@"Login"
                                            otherButtonTitles:@"Cancel", nil];
    message.tag = 0;
    [message show];
}

- (void) saveButtonPressed
{
    OPEOSMData* data = [[OPEOSMData alloc] init];
    if (![data canAuth])
    {
        [self showOauthError];
    }
    else if (![theNewNode isEqualToNode:node]) 
    {
        [self.view addSubview:HUD];
        [HUD setLabelText:@"Saving..."];
        [HUD show:YES];
        dispatch_queue_t q = dispatch_queue_create("queue", NULL);
        dispatch_async(q, ^{
            NSLog(@"saveBottoPressed");
            
            if ([theNewNode.tags objectForKey:@"name"]) {
                NSString * newName = [OPEOSMData backToHTML:[theNewNode.tags objectForKey:@"name"]];
                [theNewNode.tags setObject:newName forKey:@"name"];
            }
            if(theNewNode.ident<0)
            {
                NSLog(@"Create Node");
                int newIdent = [data createNode:theNewNode];
                NSLog(@"New Id: %d", newIdent);
                theNewNode.ident = newIdent;
                theNewNode.version = 1;
                node = theNewNode;
                if(delegate)
                {
                    if ([theNewNode.tags objectForKey:@"name"]) {
                        NSString * newName = [OPEOSMData HTMLFix:[theNewNode.tags objectForKey:@"name"]];
                        [theNewNode.tags setObject:newName forKey:@"name"];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate createdNode:node];
                    });
                }
            }
            else
            {
                NSLog(@"Update Node");
                int version = [data updateNode:theNewNode];
                NSLog(@"Version after update: %d",version);
                theNewNode.version = version;
                node = theNewNode;
                if(delegate)
                {
                    if ([theNewNode.tags objectForKey:@"name"]) {
                        NSString * newName = [OPEOSMData HTMLFix:[theNewNode.tags objectForKey:@"name"]];
                        [theNewNode.tags setObject:newName forKey:@"name"];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate updatedNode:node];
                    });
                }
            }
            
        });
        
        dispatch_release(q);

        
    }
    else {
        NSLog(@"NO CHANGES TO UPLOAD");
    }
     nodeIsEdited = NO;
}

- (void) deleteButtonPressed
{
    OPEOSMData* data = [[OPEOSMData alloc] init];
    if (![data canAuth])
    {
        [self showOauthError];
    }
    else {
        NSLog(@"Delete Button Pressed");
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Delete Point of Interest"
                                                          message:@"Are you Sure you want to delete this node?"
                                                         delegate:self
                                                cancelButtonTitle:@"Yes"
                                                otherButtonTitles:@"Cancel",nil];
        message.tag = 1;
        
        [message show];
    }
   
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    NSLog(@"AlertView Tag %d",alertView.tag);
    if(alertView.tag == 0)
    {
        if([title isEqualToString:@"Login"])
        {
            NSLog(@"SignInToOSM");
            [self signInToOSM];
        }
        
    }
    else if (alertView.tag == 1) {
        if([title isEqualToString:@"Yes"])
        {
            NSLog(@"Button OK was selected.");
            
            [self.view addSubview:HUD];
            [HUD setLabelText:@"Deleting..."];
            [HUD show:YES];
            dispatch_queue_t q = dispatch_queue_create("queue", NULL);
            dispatch_async(q, ^{
                if ([node.tags objectForKey:@"name"]) {
                    NSString * newName = [OPEOSMData backToHTML:[node.tags objectForKey:@"name"]];
                    [theNewNode.tags setObject:newName forKey:@"name"];
                }
                OPEOSMData* data = [[OPEOSMData alloc] init];
                [data deleteNode:node];
                if(delegate)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate deletedNode:node];
                    });
                    
                }
            });
            
            dispatch_release(q);
            
        }
        else if([title isEqualToString:@"Cancel"])
        {
            NSLog(@"Button Cancel was selected.");
        }
    }
    
   
    
}

- (void) newTag:(NSDictionary *)tag
{
    NSString * osmKey = [tag objectForKey:@"osmKey"];
    NSString * osmValue = [tag objectForKey:@"osmValue"];
    
    if (![osmValue isEqualToString:@""]) 
    {
        [theNewNode.tags setObject:osmValue forKey:osmKey];
    }
    else {
        [theNewNode.tags removeObjectForKey:osmKey];
    }
    [self.tableView reloadData];
    NSLog(@"NewNode: %@",theNewNode.tags);
}
/*
- (void) setText:(NSString *)text
{
    NSString * newName = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString * oldName = [theNewNode.tags objectForKey:@"name"];
    if (![newName isEqualToString:@""]) 
    {
        NSLog(@"check string: %@",newName);
        if (oldName) 
        {
            if(![oldName isEqualToString:newName])
            {
                [theNewNode.tags setObject:text forKey:@"name"];
                nodeIsEdited = YES;
            }
        }
        else {
            [theNewNode.tags setObject:text forKey:@"name"];
            nodeIsEdited = YES;
        }
    }
    else {
        if (oldName) {
            [theNewNode.tags removeObjectForKey:@"name"];
            nodeIsEdited = YES;
        }
        NSLog(@"emptyString");
        
    }
    NSLog(@"NewNode: %@",theNewNode.tags);
    
    //NSLog(@"we're back %@", text);
    //[self.tableView reloadData];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}
*/
- (void) setCategoryAndType:(NSDictionary *)cAndT
{
    if ([catAndType count]==2) {
        [tagInterpreter removeCatAndType:[[NSDictionary alloc] initWithObjectsAndKeys:[catAndType objectAtIndex:1],[catAndType objectAtIndex:0], nil] fromNode:theNewNode];
    }
    NSString * newCategory = [cAndT objectForKey:@"category"];
    NSString * newType = [cAndT objectForKey:@"type"];
    
    
    NSDictionary * KV = [tagInterpreter getOSmKeysValues:[[NSDictionary alloc] initWithObjectsAndKeys:newType,newCategory, nil]];
    NSLog(@"catAndType: %@",cAndT);
    //NSLog(@"KV: %@",osmKeyValue);
    
    
    NSLog(@"ID: %d",theNewNode.ident);
    NSLog(@"Version: %d",theNewNode.version);
    NSLog(@"Lat: %f",theNewNode.coordinate.latitude);
    NSLog(@"Lon: %f",theNewNode.coordinate.longitude);
    NSLog(@"Tags: %@",theNewNode.tags);
    
    [theNewNode.tags addEntriesFromDictionary:KV];
    
    
    //NSLog(@"id: %@ \n version: %@ \n lat: %f \n lon: %f \n newTags: %@ \n ",theNewNode.ident,theNewNode.version,theNewNode.coordinate.latitude,theNewNode.coordinate.longitude,theNewNode.tags);
    NSLog(@"ID: %d",theNewNode.ident);
    NSLog(@"Version: %d",theNewNode.version);
    NSLog(@"Lat: %f",theNewNode.coordinate.latitude);
    NSLog(@"Lon: %f",theNewNode.coordinate.longitude);
    NSLog(@"Tags: %@",theNewNode.tags);
    theNewNode.image = [tagInterpreter getImageForNode:theNewNode];
    
    catAndType = [[NSArray alloc] initWithObjects: newCategory ,newType, nil];
    //[self.tableView reloadData];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}



- (void)checkSaveButton
{
    NSLog(@"cAndT count %d",[catAndType count]);
    if([theNewNode isEqualToNode:node] || [catAndType count]!=2)
    {
        NSLog(@"NO CHANGES YET");
        self.saveButton.enabled= NO;
    }
    else {
        self.saveButton.enabled = YES;
    }
}
-(void) uploadComplete:(NSNotification *)notification
{
    NSLog(@"got notification");
    
    dispatch_async(dispatch_get_main_queue(), ^{
    [self.HUD hide:YES];
    node = theNewNode;
    [self checkSaveButton];
    [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void) viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [self checkSaveButton];
    
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

#pragma - OAuth
- (void)viewController:(GTMOAuthViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuthAuthentication *)auth
                 error:(NSError *)error {
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
        NSLog(@"Suceeed");
        //[self dismissModalViewControllerAnimated:YES];
    }
    
    //[self updateUI];
}


- (GTMOAuthAuthentication *)osmAuth {
    NSString *myConsumerKey = @"pJbuoc7SnpLG5DjVcvlmDtSZmugSDWMHHxr17wL3";    // pre-registered with service
    NSString *myConsumerSecret = @"q5qdc9DvnZllHtoUNvZeI7iLuBtp1HebShbCE9Y1"; // pre-assigned by service
    
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
    
    [[self navigationController] pushViewController:viewController animated:YES];
}

@end
