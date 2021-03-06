#import "LoginWindow.h"
#import "Result.h"
#import "ResultsView.h"

@implementation LoginWindow

@synthesize accountTypes, accountInput, accountPicker, usernameInput, passwordInput, loginButton, url, app, results, periods, currentPeriod;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [table setBackgroundColor:[UIColor clearColor]];
    
    self.app = (FHICTAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    periods = [[NSMutableArray alloc] init];
    
    self.accountTypes = [[NSArray alloc] initWithObjects:@"Student", @"Werknemer", @"Relatie", nil];
    
    self.accountPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 480, 320, 270)];
    self.accountPicker.delegate = self;
    self.accountPicker.dataSource = self;
    [self.view addSubview:self.accountPicker];
    
    authSucces = YES;
    
    self.url = @"https://dpf-hi.fontys.nl/ReportServer?%2fStudentResulaat%2fStudentResultaat&rs%3aFormat=XML";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if([indexPath row] == 0)
    {
        [cell.textLabel setText:@"PCN"];
        self.usernameInput = [[UITextField alloc] initWithFrame:CGRectMake(130, 0, 180, 44)];
        [self.usernameInput setKeyboardType:UIKeyboardTypeNumberPad];
        [self.usernameInput setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [self.usernameInput setText:[prefs objectForKey:@"username"]];
        [cell addSubview:self.usernameInput];
    }
    else if([indexPath row] == 1)
    {
        [cell.textLabel setText:@"Wachtwoord"];
        self.passwordInput = [[UITextField alloc] initWithFrame:CGRectMake(130, 0, 180, 44)];
        [self.passwordInput setSecureTextEntry:YES];
        [self.passwordInput setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [self.passwordInput setText:[prefs objectForKey:@"password"]];
        [cell addSubview:self.passwordInput];
    }
    else
    {
        [cell.textLabel setText:@"Type"];
        self.accountInput = [[UITextField alloc] initWithFrame:CGRectMake(130, 0, 180, 44)];
        [self.accountInput setText:[prefs objectForKey:@"accounttype"]];
        self.accountInput.inputView = accountPicker;
        [self.accountInput setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [cell addSubview:self.accountInput];
    }    
    return cell;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.accountTypes count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.accountTypes objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.accountInput setText:[self.accountTypes objectAtIndex:row]];
}

- (IBAction)doLogin:(id)sender
{
    [usernameInput resignFirstResponder];
    [passwordInput resignFirstResponder];
    [accountInput resignFirstResponder];
    NSLog(@"Starting authentication");
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:30.0];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
    [connection release];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] == 0) {
        //NSLog(@"received authentication challenge"); 
        NSString *authString;
        if([self.accountInput.text isEqualToString:@"Student"])
        {
            authString = [[self.usernameInput text] stringByAppendingString:@"@student.fontys.nl"];
        }
        else if([self.accountInput.text isEqualToString:@"Werknemer"])
        {
            authString = [[self.usernameInput text] stringByAppendingString:@"@fontys.nl"];        
        }
        else if([self.accountInput.text isEqualToString:@"Relatie"])
        {
            authString = [[self.usernameInput text] stringByAppendingString:@"@relatie.fontys.nl"];
        }
        //NSLog(authString);
        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:authString
                                                                    password:self.passwordInput.text
                                                                 persistence:NSURLCredentialPersistenceForSession];
        //NSLog(@"credential created");
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
        //NSLog(@"responded to authentication challenge");    
    }
    else {
        //NSLog(@"previous authentication failure");
        NSLog(@"Login Failed");
        authSucces = NO;
        UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:@"Fout" 
                                                               message:@"De ingevoerde gebruikersnaam of wachtwoord is fout!"
                                                              delegate:self 
                                                     cancelButtonTitle:@"Ok" 
                                                     otherButtonTitles:nil];
        [failureAlert show];
        [failureAlert release];
        [connection cancel];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if(authSucces)
    {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:[usernameInput text] forKey:@"username"];
        [prefs setObject:[accountInput text] forKey:@"accounttype"];
        [prefs synchronize];
        [self parseXML];
        [app loginComplete];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"connectionerror");
}

- (void)parseXML
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:YES];
    [parser setShouldReportNamespacePrefixes:YES];
    [parser setShouldResolveExternalEntities:YES];
    [parser parse];
    [parser release];
}

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqualToString:@"Report"])
    {        
        Student *student = [[Student alloc] init];
        student.student = [attributeDict objectForKey:@"studNaam"];
        student.study = [attributeDict objectForKey:@"studieNaam"];
        student.pcn = [[attributeDict objectForKey:@"studPcn"] intValue];
        student.studentnumber = [[attributeDict objectForKey:@"studNr"] intValue];
        student.slb1 = [attributeDict objectForKey:@"slb1Naam"];
        student.slb2 = [attributeDict objectForKey:@"slb2Naam"];
        student.asses11 = [attributeDict objectForKey:@"asse1PNaam"];
        student.asses12 = [attributeDict objectForKey:@"asse2PNaam"];
        student.asses21 = [attributeDict objectForKey:@"asse1PNaam2"];
        student.asses22 = [attributeDict objectForKey:@"asse2PNaam2"];
        student.asses31 = [attributeDict objectForKey:@"asse1PNaam3"];
        student.asses32 = [attributeDict objectForKey:@"asse2PNaam3"];        
        app.report.student = student;
        [student release];
    }
    
    if([elementName isEqualToString:@"table1_periodeNaam"])
    {
        Period *period = [[Period alloc] init];
        period.description = [attributeDict objectForKey:@"Textbox25"];
        currentPeriod = period;
        results = [[NSMutableArray alloc] init];
    }
    
    if([elementName isEqualToString:@"Detail"])
    {
        Result *result = [[Result alloc] init];
        result.course = [attributeDict objectForKey:@"vakNaam"];
        result.description = [attributeDict objectForKey:@"beschrijving"];
        double r = [[attributeDict objectForKey:@"resultaat"] doubleValue];
        if(r == 0 || r <= 10)
            result.result = [attributeDict objectForKey:@"resultaat"];
        else
            result.result = [[NSString stringWithFormat:@"%f", r/10] substringToIndex:3];
        result.SBU = [[attributeDict objectForKey:@"SBU"] intValue];
        result.comment = [attributeDict objectForKey:@"Opmerking"];
        result.A1 = [attributeDict objectForKey:@"A1"];
        result.A2 = [attributeDict objectForKey:@"A2"];
        result.A3 = [attributeDict objectForKey:@"A3"];
        result.B1 = [attributeDict objectForKey:@"B1"];
        result.B2 = [attributeDict objectForKey:@"B2"];
        result.B3 = [attributeDict objectForKey:@"B3"];
        result.B4 = [attributeDict objectForKey:@"B4"];
        result.B5 = [attributeDict objectForKey:@"B5"];
        [results addObject:result];
        [result release];
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if([elementName isEqualToString:@"table1_periodeNaam"])
    {
        currentPeriod.results = results;
        [periods insertObject:currentPeriod atIndex:0];
    }
    if([elementName isEqualToString:@"Report"])
    {
        app.report.periods = [[NSArray alloc] initWithArray:periods];
        NSLog(@"parsed %d periods", [app.report.periods count]);
        NSInteger resultcount = 0;
        for(Period *p in app.report.periods)
        {
            resultcount += [p.results count];
        }
        NSLog(@"parsed %d results", resultcount);
    }
}

- (void)describeDictionary:(NSDictionary *)dict
{ 
    NSArray *keys;
    int i, count;
    id key, value;
    
    keys = [dict allKeys];
    count = [keys count];
    for (i = 0; i < count; i++)
    {
        key = [keys objectAtIndex: i];
        value = [dict objectForKey: key];
        NSLog (@"Key: %@ for value: %@", key, value);
    }
}

- (void)dealloc
{
    [accountTypes release];
    [results release];
    [periods release];
    [currentPeriod release];
    [accountInput release];
    [accountPicker release];
    [usernameInput release];
    [passwordInput release];
    [loginButton release];
    [url release];
    [app release];
    [super dealloc];
}

@end
