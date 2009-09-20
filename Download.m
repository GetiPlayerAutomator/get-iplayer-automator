//
//  Download.m
//  Get_iPlayer GUI
//
//  Created by Thomas Willson on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Download.h"

@implementation Download
#pragma mark Overridden Methods
- (id)initWithProgramme:(Programme *)tempShow :(id)sender
{
	[super init];
	runAgain = NO;
	running=YES;
	foundLastLine=NO;
	errorCache = [[NSMutableString alloc] init];
	processErrorCache = [NSTimer scheduledTimerWithTimeInterval:.25 target:self selector:@selector(processError) userInfo:nil repeats:YES];
	
	log = [[NSMutableString alloc] initWithString:@""];
	nc = [NSNotificationCenter defaultCenter];
	show = tempShow;
	[self addToLog:[NSString stringWithFormat:@"Downloading %@", [show showName]]];
	i=0;
	//Prepare Arguments
		//Initialize Paths
	NSString *bundlePath = [[NSString alloc] initWithString:[[NSBundle mainBundle] bundlePath]];
	NSString *getiPlayerPath = [bundlePath stringByAppendingString:@"/Contents/Resources/get_iplayer.pl"];
	NSString *mplayerPath = [bundlePath stringByAppendingString:@"/Contents/Resources/mplayer"];
	NSString *flvstreamerPath = [bundlePath stringByAppendingString:@"/Contents/Resources/flvstreamer_macosx"];
#ifdef __i386__
	NSString *ffmpegPath = [bundlePath stringByAppendingString:@"/Contents/Resources/ffmpeg"];
#else
	NSString *ffmpegPath = nil;
#endif
	NSString *downloadPath = [[NSString alloc] initWithString:[[NSUserDefaults standardUserDefaults] valueForKey:@"DownloadPath"]];
		//Initialize Formats
	NSArray *formatKeys = [NSArray arrayWithObjects:@"iPhone",@"Flash - High",@"Flash - Low",@"Flash - HD",@"Flash - Standard",@"Flash - Normal",@"Flash - Very High",nil];
	NSArray *formatObjects = [NSArray arrayWithObjects:@"iphone",@"flashhigh",@"flashlow",@"flashhd",@"flashstd",@"flashstd",@"flashvhigh",nil];
	NSDictionary *formats = [[NSDictionary alloc] initWithObjects:formatObjects forKeys:formatKeys];
	NSString *defaultFormat = [formats objectForKey:[[NSUserDefaults standardUserDefaults] valueForKey:@"DefaultFormat"]];
	NSString *alternateFormat = [formats objectForKey:[[NSUserDefaults standardUserDefaults] valueForKey:@"AlternateFormat"]];
		//Set Proxy Argument
	NSString *proxyArg;
	NSString *partialProxyArg;
	NSString *proxyOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"Proxy"];
	if ([proxyOption isEqualToString:@"None"])
	{
		//No Proxy
		proxyArg = NULL;
	}
	else if ([proxyOption isEqualToString:@"Custom"])
	{
		//Get the Custom Proxy.
		proxyArg = [[NSString alloc] initWithFormat:@"-p%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"CustomProxy"]];
	}
	else
	{
		//Get provided proxy from my server.
		NSURL *proxyURL = [[NSURL alloc] initWithString:@"http://tom-tech.com/get_iplayer/proxy.txt"];
		NSURLRequest *proxyRequest = [NSURLRequest requestWithURL:proxyURL
													  cachePolicy:NSURLRequestReturnCacheDataElseLoad
												  timeoutInterval:30];
		NSData *urlData;
		NSURLResponse *response;
		NSError *error;
		urlData = [NSURLConnection sendSynchronousRequest:proxyRequest
										returningResponse:&response
													error:&error];
		if (!urlData)
		{
			NSAlert *alert = [NSAlert alertWithMessageText:@"Provided Proxy could not be retrieved!" 
											 defaultButton:nil 
										   alternateButton:nil 
											   otherButton:nil 
								 informativeTextWithFormat:@"No proxy will be used.\r\rError: %@", [error localizedDescription]];
			[alert runModal];
			[self addToLog:@"Proxy could not be retrieved. No proxy will be used."];
			proxyArg=NULL;
		}
		else
		{
			NSString *providedProxy = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
			proxyArg = [[NSString alloc] initWithFormat:@"-phttp://%@", providedProxy];
		}
	}
		//Partial Proxy?
	if (/*[[[NSUserDefaults standardUserDefaults] valueForKey:@"PartialProxy"] isEqualTo:[NSNumber numberWithBool:YES]]*/YES)
	{
		partialProxyArg = [[NSString alloc] initWithString:@"--partial-proxy"];
	}
	else
	{
		partialProxyArg = NULL;
	}
		//Initialize the rest of the arguments
	NSString *noWarningArg = [[NSString alloc] initWithString:@"--nocopyright"];
	NSString *noExpiryArg = [[NSString alloc] initWithString:@"--nopurge"];
	NSString *mplayerArg = [[NSString alloc] initWithFormat:@"--mplayer=%@", mplayerPath];
	NSString *flvstreamerArg = [[NSString alloc] initWithFormat:@"--flvstreamer=%@", flvstreamerPath];
	NSString *ffmpegArg;
	if (ffmpegPath) ffmpegArg = [[NSString alloc] initWithFormat:@"--ffmpeg=%@", ffmpegPath];
	else ffmpegArg = nil;
	NSString *downloadPathArg = [[NSString alloc] initWithFormat:@"--output=%@", downloadPath];
	NSString *subDirArg = [[NSString alloc] initWithString:@"--subdir"];
	NSString *formatArg = [[NSString alloc] initWithFormat:@"--modes=%@,%@", defaultFormat, alternateFormat];
	NSString *getArg = [[NSString alloc] initWithFormat:@"--get"];
	NSString *searchArg = [[NSString alloc] initWithFormat:@"%@", [show pid]];
	NSString *versionArg = [[NSString alloc] initWithString:@"--versions=default"];
	//We don't want this to refresh now!
	NSString *cacheExpiryArg = @"-e604800";
	NSString *folder = @"~/Library/Application Support/Get iPlayer Automator/";
		//Profile Override Argument
	folder = [folder stringByExpandingTildeInPath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath: folder] == NO)
	{
		[fileManager createDirectoryAtPath: folder attributes: nil];
	}
	profileDirArg = [[NSString alloc] initWithFormat:@"--profile-dir=%@", folder];
	
		//Add Arguments that can't be NULL
	NSMutableArray *args = [[NSMutableArray alloc] initWithObjects:getiPlayerPath,profileDirArg,noWarningArg,noExpiryArg,mplayerArg,flvstreamerArg,cacheExpiryArg,downloadPathArg,
					 subDirArg,formatArg,getArg,searchArg,@"--attempts=5",@"--whitespace",@"--file-prefix=<name> - <episode>",@"--nopurge",versionArg,proxyArg,partialProxyArg,nil];
		//Verbose?
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"Verbose"] isEqualTo:[NSNumber numberWithBool:YES]])
		[args addObject:[[NSString alloc] initWithString:@"--verbose"]];
	if (ffmpegArg) [args addObject:ffmpegArg];
	task = [[NSTask alloc] init];
	pipe = [[NSPipe alloc] init];
	errorPipe = [[NSPipe alloc] init];
	
	[task setArguments:args];
	[task setLaunchPath:@"/usr/bin/perl"];
	[task setStandardOutput:pipe];
	[task setStandardError:errorPipe];
	
	fh = [pipe fileHandleForReading];
	errorFh = [errorPipe fileHandleForReading];
	
	[nc addObserver:self
		   selector:@selector(DownloadDataReady:)
			   name:NSFileHandleReadCompletionNotification
			 object:fh];
	[nc addObserver:self
		   selector:@selector(ErrorDataReady:)
			   name:NSFileHandleReadCompletionNotification
			 object:errorFh];
	[task launch];
	[fh readInBackgroundAndNotify];
	[errorFh readInBackgroundAndNotify];
	[show setValue:@"Starting..." forKey:@"status"];
	
	//Prepare UI
	[currentProgress setStringValue:@"Beginning..."];
	[currentIndicator setMaxValue:100];
	[currentIndicator setMinValue:0];
	[currentIndicator setIndeterminate:NO];
	return self;
}
- (id)description
{
	return [NSString stringWithFormat:@"Download (ID=%@)", [show pid]];
}
#pragma mark Task Control
- (void)DownloadDataReady:(NSNotification *)note
{
	[[pipe fileHandleForReading] readInBackgroundAndNotify];
	NSData *d;
    d = [[note userInfo] valueForKey:NSFileHandleNotificationDataItem];
	
    if ([d length] > 0) {
		NSString *s = [[NSString alloc] initWithData:d
											encoding:NSUTF8StringEncoding];
		[self processGetiPlayerOutput:s];
	}
	else
	{
		i++;
		if (i>20 && running)
		{
			running=NO;
			//Download Finished Handler
			task = nil;
			pipe = nil;
			if (runDownloads)
			{
				NSString *lastLine;
				if (!foundLastLine)
				{
					unsigned length = [log length];
					unsigned paraStart = 0, paraEnd = 0, contentsEnd = 0;
					NSMutableArray *array = [NSMutableArray array];
					NSRange currentRange;
					while (paraEnd < length) {
						[log getParagraphStart:&paraStart end:&paraEnd
									  contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
						currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
						[array addObject:[log substringWithRange:currentRange]];
					}
					lastLine = [array objectAtIndex:([array count]-1)];
					NSLog(@"Last Line = %@", lastLine);
				}
				else 
				{
					lastLine = LastLine;
				}

				NSScanner *scn = [NSScanner scannerWithString:lastLine];
				if ([lastLine hasPrefix:@"INFO: Recorded"])
				{
					NSLog(@"Download: Success");
					[show setValue:[NSNumber numberWithBool:YES] forKey:@"complete"];
					[show setValue:[NSNumber numberWithBool:YES] forKey:@"successful"];
					[show setValue:@"Download Complete" forKey:@"status"];
					NSScanner *scanner = [NSScanner scannerWithString:lastLine];
					NSString *path;
					[scanner scanString:@"INFO: Recorded" intoString:nil];
					if (![scanner scanFloat:nil])
					{
						[scanner scanUpToString:@"kjkjkjkjk" intoString:&path];
					}
					else
					{
						[scanner scanUpToString:@"to" intoString:nil];
						[scanner scanString:@"to " intoString:nil];
						[scanner scanUpToString:@"kjkfjkj" intoString:&path];
					}
					[show setPath:path];
					[self addToLog:[NSString stringWithFormat:@"%@ Completed Successfully",[show showName]]];
				}
				else if ([lastLine hasPrefix:@"INFO: All streaming threads completed"])
				{
					NSLog(@"Download: Success");
					[show setValue:[NSNumber numberWithBool:YES] forKey:@"complete"];
					[show setValue:[NSNumber numberWithBool:YES] forKey:@"successful"];
					[show setValue:@"Download Complete" forKey:@"status"];
					[show setPath:@"Unknown"];
				}
				else if ([scn scanUpToString:@"Already in download history" intoString:nil] && 
						 [scn scanString:@"Already in" intoString:nil])
				{
					NSLog(@"In History");
					[show setValue:[NSNumber numberWithBool:YES] forKey:@"complete"];
					[show setValue:[NSNumber numberWithBool:NO] forKey:@"successful"];
					[show setValue:@"Failed: Download in History" forKey:@"status"];
					[self addToLog:[NSString stringWithFormat:@"%@ Failed",[show showName]]];
				}
				else
				{
					NSLog(@"Download: Failure");
					[show setValue:[NSNumber numberWithBool:YES] forKey:@"complete"];
					[show setValue:[NSNumber numberWithBool:NO] forKey:@"successful"];
					[show setValue:@"Download Failed" forKey:@"status"];
					[self addToLog:[NSString stringWithFormat:@"%@ Failed",[show showName]]];
				}
			}
			NSLog(@"Posting notification");
			[nc postNotificationName:@"DownloadFinished" object:show];
		}
	}
}
- (void)ErrorDataReady:(NSNotification *)note
{
	[[errorPipe fileHandleForReading] readInBackgroundAndNotify];
	NSData *d;
    d = [[note userInfo] valueForKey:NSFileHandleNotificationDataItem];
	
    if ([d length] > 0)
	{
		[errorCache appendString:[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
	}
	else
	{
		i++;
		if (i>20)
		{
			//Close the error pipe when it is empty.
			errorPipe = nil;
		}
	}
}
- (void)processError
{
	if (running)
	{
		NSString *outp = [errorCache copy];
		errorCache = [NSMutableString stringWithString:@""];
		if ([outp length] > 0) {
			BOOL status=YES;
			NSString *outpt = [[NSString alloc] initWithString:outp];
			NSString *string = [NSString stringWithString:outpt];
			NSUInteger length = [string length];
			NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
			NSMutableArray *array = [NSMutableArray array];
			NSRange currentRange;
			while (paraEnd < length) {
				[string getParagraphStart:&paraStart end:&paraEnd
							  contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
				currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
				[array addObject:[string substringWithRange:currentRange]];
			}
			for (NSString *s in array)
			{
				NSString *s2;
				NSScanner *scanner = [NSScanner scannerWithString:s];
				//Check if BBC Flash status Message
				if (![scanner scanFloat:nil])
				{
					if ([s length] != 0)
					{
						//If not...
						s2 = @"0.0% - (0.0 MB/~0.0 MB) -- Initializing...";
						[self addToLog:s noTag:YES];
						status=NO;
						[scanner setScanLocation:0];
						if ([s hasPrefix:@"ERROR:"] || [s hasPrefix:@"\rERROR:"] || [s hasPrefix:@"\nERROR:"])
						{
							NSLog(@"here");
							if ([scanner scanUpToString:@"corrupt file!" intoString:nil])
							{
								NSAlert *alert = [NSAlert alertWithMessageText:@"Unresumable File!" 
																 defaultButton:nil 
															   alternateButton:nil 
																   otherButton:nil 
													 informativeTextWithFormat:@"Try this download again. If it fails with the same message again, please move or rename the partial file for %@",[show showName]];
								[task interrupt];
								[alert runModal];
							}
						}
					}
					else
					{
						status=NO;
						s2=nil;
						[scanner setScanLocation:0];
					}
				}
				else
				{
					//If so...
					[scanner setScanLocation:0];
					[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
					status=YES;
				}
				//If An FLVStreamer Status Message...
				double downloaded, elapsed, percent, total;
				if ([scanner scanDouble:&downloaded] && status)
				{
					[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
					if (![scanner scanDouble:&elapsed]) elapsed=0.0;
					[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
					if (![scanner scanDouble:&percent]) percent=0.0;
					if (downloaded>0 && percent>0) total = ((downloaded/1024)/(percent/100));
					else total=0;
					[self setCurrentProgress:[NSString stringWithFormat:@"%.1f%% - (%.2f MB/~%.0f MB) -- %@",percent,(downloaded/1024),total,[show valueForKey:@"showName"]]];
					[self setPercentage:percent];
					[show setValue:[NSString stringWithFormat:@"Downloading: %.1f%%", percent] forKey:@"status"];
				}
				else
				{	
					//Otherwise, use the indeterminate display.
					if (s2 != nil) 
					{
						[self setCurrentProgress:s2];
						[self setPercentage:102];
						[show setValue:@"Downloading" forKey:@"status"];
					}
				}
			}
			
		}
	}
}	
- (void)cancelDownload:(id)sender
{
	//Some basic cleanup.
	[task interrupt];
	[nc removeObserver:self name:NSFileHandleReadCompletionNotification object:fh];
	[nc removeObserver:self name:NSFileHandleReadCompletionNotification object:errorFh];
	task = nil;
	[show setValue:@"Cancelled" forKey:@"status"];
	[self addToLog:@"Download Cancelled"];
}
- (void)processGetiPlayerOutput:(NSString *)outp
{
	//Separate the output by line.
	NSString *outpt = [[NSString alloc] initWithString:outp];
	NSString *string = [NSString stringWithString:outpt];
	NSUInteger length = [string length];
	NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
	NSMutableArray *array = [NSMutableArray array];
	NSRange currentRange;
	while (paraEnd < length) {
		[string getParagraphStart:&paraStart end:&paraEnd
					  contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
		currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
		[array addObject:[string substringWithRange:currentRange]];
	}
	//Parse each line individually.
	for (NSString *output in array)
	{
		if ([output hasPrefix:@"INFO: Recorded"])
		{
			LastLine = [NSString stringWithString:output];
			foundLastLine=YES;
		}
		else if ([output hasPrefix:@"INFO:"] || [output hasPrefix:@"WARNING:"] || [output hasPrefix:@"ERROR:"] || 
			[output hasSuffix:@"default"] || [output hasPrefix:[show pid]])
		{
			//Add Status Message to Log
			[self addToLog:output noTag:YES];
		}
		else if ([output hasPrefix:@"Threads:"])
		{
			//If it is an MPlayer (ITV) status message:
			NSScanner *scanner = [NSScanner scannerWithString:output];
			
			NSString *threadRecieved;
			[scanner scanUpToString:@"recorded" intoString:&threadRecieved];
			
			NSScanner *threadRecievedScanner = [NSScanner scannerWithString:threadRecieved];
			double downloaded=0;
			while ([threadRecievedScanner scanUpToString:@")" intoString:nil]) 
			{
				[threadRecievedScanner scanString:@") " intoString:nil];
				double thread;
				[threadRecievedScanner scanDouble:&thread];
				downloaded = downloaded + thread;
			}
			NSInteger speed;
			[scanner scanUpToString:@"(" intoString:nil];
			[scanner scanString:@"(" intoString:nil];
			[scanner scanInteger:&speed];
			
			[self setCurrentProgress:[NSString stringWithFormat:@"Unknown%% (%3.2fMB/Unknown) - %5.1fKB/s -- %@",
									  downloaded,
									  [[NSDecimalNumber numberWithInteger:speed] doubleValue]/8,
									  [show showName]]];
			[show setValue:@"Downloading..." forKey:@"status"];
			[self setPercentage:102];

		}
			
		else
		{
			//Process iPhone/Podcast/Radio Downloads Status Message
			NSScanner *scanner = [NSScanner scannerWithString:output];
			NSDecimal recieved, total, percentage;
			NSInteger speed=0;
			NSString *timeRemaining;
			if(![scanner scanDecimal:&recieved]) recieved = [[NSNumber numberWithInt:0]decimalValue];
			[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] 
									intoString:nil];
			if(![scanner scanDecimal:&total]) total = [[NSNumber numberWithInt:0]decimalValue];
			[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] 
									intoString:nil];
			if(![scanner scanInteger:&speed]) speed = [[NSNumber numberWithInt:0]integerValue];
			[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] 
									intoString:nil];
			if(![scanner scanDecimal:&percentage]) percentage = [[NSNumber numberWithInt:0]decimalValue];
			[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] 
									intoString:nil];
			[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"a"] 
									intoString:&timeRemaining];
			double adjustedSpeed = [[NSNumber numberWithInteger:speed] doubleValue]/8;
			[self setPercentage:[[NSDecimalNumber decimalNumberWithDecimal:percentage] doubleValue]];
			if ([[NSDecimalNumber decimalNumberWithDecimal:total] doubleValue] < 5.00 && [[NSDecimalNumber decimalNumberWithDecimal:recieved] doubleValue] > 0)
			{
				[self setCurrentProgress:[NSString stringWithFormat:@"%3.1f%% (%3.2fMB/%3.2fMB) - %5.1fKB/s -- Getting MOV atom.",
										  [[NSDecimalNumber decimalNumberWithDecimal:percentage] doubleValue],
										  [[NSDecimalNumber decimalNumberWithDecimal:recieved] doubleValue],
										  [[NSDecimalNumber decimalNumberWithDecimal:total] doubleValue],
										  adjustedSpeed,[show showName]]];
				[show setValue:[NSString stringWithFormat:@"Getting MOV atom: %3.1f%%",
								[[NSDecimalNumber decimalNumberWithDecimal:percentage] doubleValue]]
						forKey:@"status"];
			}
			else if ([[NSDecimalNumber decimalNumberWithDecimal:total] doubleValue] == 0)
			{
				[self setCurrentProgress:[NSString stringWithFormat:@"%3.1f%% (%3.2fMB/%3.2fMB) - %5.1fKB/s -- Initializing...",
										  [[NSDecimalNumber decimalNumberWithDecimal:percentage] doubleValue],
										  [[NSDecimalNumber decimalNumberWithDecimal:recieved] doubleValue],
										  [[NSDecimalNumber decimalNumberWithDecimal:total] doubleValue],
										  adjustedSpeed,[show showName]]];
				[show setValue:[NSString stringWithFormat:@"Initializing: %3.1f%%",
								[[NSDecimalNumber decimalNumberWithDecimal:percentage] doubleValue]]
						forKey:@"status"];		
			}
			else
			{
				[self setCurrentProgress:[NSString stringWithFormat:@"%3.1f%% (%3.2fMB/%3.2fMB) - %.1fKB/s -- %@",
				 [[NSDecimalNumber decimalNumberWithDecimal:percentage] doubleValue],
				 [[NSDecimalNumber decimalNumberWithDecimal:recieved] doubleValue],
				 [[NSDecimalNumber decimalNumberWithDecimal:total] doubleValue],
										  adjustedSpeed,[show showName]]];
				[show setValue:[NSString stringWithFormat:@"Downloading: %3.1f%%",
								[[NSDecimalNumber decimalNumberWithDecimal:percentage] doubleValue]]
						forKey:@"status"];
			}
		}
	}
}
#pragma mark Notification Posters
- (void)addToLog:(NSString *)logMessage noTag:(BOOL)b
{
	if (b)
	{
		[nc postNotificationName:@"AddToLog" object:nil userInfo:[NSDictionary dictionaryWithObject:logMessage forKey:@"message"]];
	}
	else
	{
		[nc postNotificationName:@"AddToLog" object:self userInfo:[NSDictionary dictionaryWithObject:logMessage forKey:@"message"]];
	}
	[log appendFormat:@"%@\n", logMessage];
}
- (void)addToLog:(NSString *)logMessage
{
	[nc postNotificationName:@"AddToLog" object:self userInfo:[NSDictionary dictionaryWithObject:logMessage forKey:@"message"]];
	[log appendFormat:@"%@\n", logMessage];
}
- (void)setCurrentProgress:(NSString *)string
{
	[nc postNotificationName:@"setCurrentProgress" object:self userInfo:[NSDictionary dictionaryWithObject:string forKey:@"string"]];
}
- (void)setPercentage:(double)d
{
	if (d<=100.0)
	{
		NSNumber *value = [[NSNumber alloc] initWithDouble:d];
		[nc postNotificationName:@"setPercentage" object:self userInfo:[NSDictionary dictionaryWithObject:value forKey:@"nsDouble"]];
	}
	else
	{
		[nc postNotificationName:@"setPercentage" object:self userInfo:nil];
	}
}
@synthesize show;
@end
