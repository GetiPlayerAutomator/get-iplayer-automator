//
//  SettingsController.m
//  Get iPlayer Automator
//
//  Created by Thomas Willson on 9/10/16.
//
//

#import "SettingsController.h"

@implementation SettingsController {
	NSDictionary *tvFormatDict;
	NSDictionary *radioFormatDict;
}

- (id) init
{
	if (!(self = [super init])) return nil;
	
	//Register Default Preferences
	NSMutableDictionary *defaultValues = [[NSMutableDictionary alloc] init];
	
	defaultValues[@"DownloadPath"] = [@"~/Movies/TV Shows" stringByExpandingTildeInPath];
	defaultValues[@"Proxy2"] = @"None";
	defaultValues[@"CustomProxy"] = @"";
	defaultValues[@"AutoRetryFailed"] = @YES;
	defaultValues[@"AutoRetryTime"] = @"30";
	defaultValues[@"AddCompletedToiTunes"] = @YES;
	defaultValues[@"DefaultBrowser"] = @"Safari";
	defaultValues[@"CacheBBC_TV"] = @YES;
	defaultValues[@"CacheBBC_Radio"] = @NO;
	defaultValues[@"CacheBBC_Podcasts"] = @NO;
	defaultValues[@"CacheExpiryTime"] = @"4";
	defaultValues[@"Verbose"] = @NO;
	defaultValues[@"SeriesLinkStartup"] = @YES;
	defaultValues[@"DownloadSubtitles"] = @NO;
	defaultValues[@"AlwaysUseProxy"] = @NO;
	defaultValues[@"XBMC_naming"] = @NO;
	defaultValues[@"KeepSeriesFor"] = @"30";
	defaultValues[@"RemoveOldSeries"] = @NO;
	defaultValues[@"QuickCache"] = @YES;
	defaultValues[@"TagShows"] = @YES;
	defaultValues[@"TestProxy"] = @YES;
	defaultValues[@"ShowDownloadedInSearch"] = @YES;
	
	defaultValues[@"AudioDescribedNew"] = @NO;
	defaultValues[@"SignedNew"] = @NO;
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	defaultValues = nil;
	
	// Migrate old AudioDescribed option
	if ([settings objectForKey:@"AudioDescribed"]) {
		[settings setObject:@YES forKey:@"AudioDescribedNew"];
		[settings setObject:@YES forKey:@"SignedNew"];
		[settings removeObjectForKey:@"AudioDescribed"];
	}
	
	// Migrate proxy option
	if ([settings objectForKey:@"Proxy"] && ![[settings objectForKey:@"Proxy"] isEqualToString:@"Provided"])
	{
		[settings setObject:[settings objectForKey:@"Proxy"] forKey:@"Proxy2"];
		[settings removeObjectForKey:@"Proxy"];
	}
	
	// remove obsolete preferences
	[settings removeObjectForKey:@"DefaultFormat"];
	[settings removeObjectForKey:@"AlternateFormat"];
	[settings removeObjectForKey:@"CacheITV_TV"];
	[settings removeObjectForKey:@"Cache4oD_TV"];
	
	//Make sure Application Support folder exists
	NSString *folder = self.applicationSupportFolderPath;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:folder])
	{
		[fileManager createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:nil];
	}
	[fileManager changeCurrentDirectoryPath:folder];
	

	tvFormatTransformer = [[EmptyToStringTransformer alloc] initWithString:@"Please select..."];
	radioFormatTransformer = [[EmptyToStringTransformer alloc] initWithString:@"Please select..."];
	itvFormatTransformer = [[EmptyToStringTransformer alloc] initWithString:@"Please select..."];
	
	[NSValueTransformer setValueTransformer:tvFormatTransformer forName:@"TVFormatTransformer"];
	[NSValueTransformer setValueTransformer:radioFormatTransformer forName:@"RadioFormatTransformer"];
	[NSValueTransformer setValueTransformer:itvFormatTransformer forName:@"ITVFormatTransformer"];
	
	return self;
}

- (void)uiLoaded
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//Read Format Preferences
	NSString *filename = @"Formats.automatorqueue";
	NSString *filePath = [self.applicationSupportFolderPath stringByAppendingPathComponent:filename];
	
	NSDictionary *rootObject;
	
	@try
	{
		rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
		[radioFormatController addObjects:[rootObject valueForKey:@"radioFormats"]];
		[tvFormatController addObjects:[rootObject valueForKey:@"tvFormats"]];
	}
	@catch (NSException *e)
	{
		[fileManager removeItemAtPath:filePath error:nil];
		NSLog(@"Unable to load saved application data. Deleted the data file.");
		rootObject=nil;
	}
	
	// clear obsolete formats
	NSMutableArray *tempTVFormats = [[NSMutableArray alloc] initWithArray:[tvFormatController arrangedObjects]];
	for (TVFormat *tvFormat in tempTVFormats) {
		if (!tvFormatDict[[tvFormat format]]) {
			[tvFormatController removeObject:tvFormat];
		}
	}
	NSMutableArray *tempRadioFormats = [[NSMutableArray alloc] initWithArray:[radioFormatController arrangedObjects]];
	for (RadioFormat *radioFormat in tempRadioFormats) {
		if (!radioFormatDict[[radioFormat format]]) {
			[radioFormatController removeObject:radioFormat];
		}
	}
	
	filename = @"ITVFormats.automator";
	filePath = [self.applicationSupportFolderPath stringByAppendingPathComponent:filename];
	@try {
		rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
		[itvFormatController addObjects:[rootObject valueForKey:@"itvFormats"]];
	}
	@catch (NSException *exception) {
		[fileManager removeItemAtPath:filePath error:nil];
		rootObject=nil;
	}
	
	//Adds Defaults to Type Preferences
	if ([[tvFormatController arrangedObjects] count] == 0)
	{
		TVFormat *format1 = [[TVFormat alloc] init];
		[format1 setFormat:@"Flash - HD"];
		TVFormat *format2 = [[TVFormat alloc] init];
		[format2 setFormat:@"Flash - Very High"];
		TVFormat *format3 = [[TVFormat alloc] init];
		[format3 setFormat:@"Flash - High"];
		[tvFormatController addObjects:@[format1,format2,format3]];
	}
	if ([[radioFormatController arrangedObjects] count] == 0)
	{
		RadioFormat *format1 = [[RadioFormat alloc] init];
		[format1 setFormat:@"Flash AAC - High"];
		RadioFormat *format2 = [[RadioFormat alloc] init];
		[format2 setFormat:@"Flash AAC - Standard"];
		RadioFormat *format3 = [[RadioFormat alloc] init];
		[format3 setFormat:@"Flash AAC - Low"];
		[radioFormatController addObjects:@[format1,format2,format3]];
	}
	if ([[itvFormatController arrangedObjects] count] == 0)
	{
		TVFormat *format0 = [[TVFormat alloc] init];
		[format0 setFormat:@"Flash - HD"];
		TVFormat *format1 = [[TVFormat alloc] init];
		[format0 setFormat:@"Flash - Very High"];
		TVFormat *format2 = [[TVFormat alloc] init];
		[format1 setFormat:@"Flash - High"];
		[itvFormatController addObjects:@[format0, format1, format2]];
	}
}

- (void)saveSettings
{
	NSString *filename = @"Formats.automatorqueue";
	NSString *filePath = [self.applicationSupportFolderPath stringByAppendingPathComponent:filename];
	
	NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
	
	[rootObject setValue:[tvFormatController arrangedObjects] forKey:@"tvFormats"];
	[rootObject setValue:[radioFormatController arrangedObjects] forKey:@"radioFormats"];
	[NSKeyedArchiver archiveRootObject:rootObject toFile:filePath];
	
	filename = @"ITVFormats.automator";
	filePath = [self.applicationSupportFolderPath stringByAppendingPathComponent:filename];
	rootObject = [NSMutableDictionary dictionary];
	[rootObject setValue:[itvFormatController arrangedObjects] forKey:@"itvFormats"];
	[NSKeyedArchiver archiveRootObject:rootObject toFile:filePath];
	
	//Store Preferences in case of crash
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)applicationSupportFolderPath
{
	return [@"~/Library/Application Support/Get iPlayer Automator/" stringByExpandingTildeInPath];
}

- (NSArray<TVFormat*> *)itvFormats
{
	return itvFormatController.arrangedObjects;
}

- (NSArray<TVFormat*> *)tvFormats
{
	return tvFormatController.arrangedObjects;
}

- (NSArray<RadioFormat*> *)radioFormats
{
	return radioFormatController.arrangedObjects;
}

- (void)initFormats
{
	NSArray *tvFormatKeys = @[@"Flash - HD",@"Flash - Very High",@"Flash - High",@"Flash - Standard",@"Flash - Low"];
	NSArray *tvFormatObjects = @[@"flashhd",@"flashvhigh",@"flashhigh",@"flashstd",@"flashlow"];
	NSArray *radioFormatKeys = @[@"Flash AAC - High",@"Flash AAC - Standard",@"Flash AAC - Low"];
	NSArray *radioFormatObjects = @[@"flashaachigh",@"flashaacstd",@"flashaaclow"];
	tvFormatDict = [[NSDictionary alloc] initWithObjects:tvFormatObjects forKeys:tvFormatKeys];
	radioFormatDict = [[NSDictionary alloc] initWithObjects:radioFormatObjects forKeys:radioFormatKeys];
}

- (NSDictionary *)tvFormatDict
{
	if (!tvFormatDict) [self initFormats];
	
	return tvFormatDict;
}

- (NSDictionary *)radioFormatDict
{
	if (!radioFormatDict) [self initFormats];
	
	return radioFormatDict;
}

@end
