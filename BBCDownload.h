//
//  Download.h
//  Get_iPlayer GUI
//
//  Created by Thomas Willson on 7/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SettingsController.h"
#import "Programme.h"
#import "TVFormat.h"
#import "RadioFormat.h"
#import "Download.h"

extern bool runDownloads;

@interface BBCDownload : Download {
	NSString *profileDirArg;
	
	BOOL runAgain;
	int noDataCount;
	
	BOOL foundLastLine;
	NSString *LastLine;
	NSString *reasonForFailure;
	
	SettingsController *settingsController;
}

- (id)initWithProgramme:(Programme *)tempShow tvFormats:(NSArray *)tvFormatList radioFormats:(NSArray *)radioFormatList proxy:(HTTPProxy *)aProxy logController:(LogController *)logger settingsController:(SettingsController *)settings;
- (void)processGetiPlayerOutput:(NSString *)outp;

@end
