//
//  SettingsController.h
//  Get iPlayer Automator
//
//  Created by Thomas Willson on 9/10/16.
//
//

#import <Foundation/Foundation.h>

#import "TVFormat.h"
#import "RadioFormat.h"
#import "EmptyToStringTransformer.h"

@interface SettingsController : NSObject {
	// Format preferences
	EmptyToStringTransformer *tvFormatTransformer;
	EmptyToStringTransformer *radioFormatTransformer;
	EmptyToStringTransformer *itvFormatTransformer;
	
	//Preferences
	NSMutableArray *tvFormatList;
	NSMutableArray *radioFormatList;
	NSMutableArray *itvFormatList;
	IBOutlet NSArrayController *tvFormatController;
	IBOutlet NSArrayController *radioFormatController;
	IBOutlet NSArrayController *itvFormatController;
	IBOutlet NSPanel *prefsPanel;
}

- (void)saveSettings;
- (void)uiLoaded;

@property(readonly) NSString *applicationSupportFolderPath;
@property(readonly) NSArray<TVFormat *> *tvFormats;
@property(readonly) NSArray<RadioFormat*> *radioFormats;
@property(readonly) NSArray<TVFormat*> *itvFormats;
@property(readonly) NSDictionary *tvFormatDict;
@property(readonly) NSDictionary *radioFormatDict;

@end
