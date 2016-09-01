//
//  GetiPlayerProxy.m
//  Get_iPlayer GUI
//
//  Created by Thomas Willson on 8/7/14.
//
//

#import "GetiPlayerProxy.h"

#import <AFNetworking/AFNetworking.h>

@implementation GetiPlayerProxy

- (id)init
{
    if (!(self = [super init])) return nil;
    
    proxyDict = [NSMutableDictionary dictionary];
    
    return self;
}

- (id)initWithLogger:(LogController *)logger {
    if (![self init]) return nil;
    
    _logger = logger;
    
    return self;
}

- (void)loadProxyInBackgroundWithCompletionHandler:(void (^)(NSDictionary *proxyDictionary))completionHandler silently:(BOOL)silent
{
    _completionHandler = completionHandler;
    [self updateProxyLoadStatus:YES message:@"Loading proxy settings..."];
    NSLog(@"INFO: Loading proxy settings...");
    [_logger addToLog:@"\n\nINFO: Loading proxy settings..."];
    [proxyDict removeAllObjects];
    NSString *proxyOption = [[NSUserDefaults standardUserDefaults] valueForKey:@"Proxy"];
    if ([proxyOption isEqualToString:@"Custom"])
    {
        NSString *customProxy = [[NSUserDefaults standardUserDefaults] valueForKey:@"CustomProxy"];
        NSLog(@"INFO: Custom Proxy: address=[%@] length=%ld", customProxy, [customProxy length]);
        [_logger addToLog:[NSString stringWithFormat:@"INFO: Custom Proxy: address=[%@] length=%ld", customProxy, [customProxy length]]];
        NSString *proxyValue = [customProxy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([proxyValue length] == 0)
        {
            NSLog(@"WARNING: Custom proxy setting was blank. No proxy will be used.");
            [_logger addToLog:@"WARNING: Custom proxy setting was blank. No proxy will be used."];
            if (!currentIsSilent)
            {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Custom proxy setting was blank.\nDownloads may fail.\nDo you wish to continue?"
                                                 defaultButton:@"No"
                                               alternateButton:@"Yes"
                                                   otherButton:nil
                                     informativeTextWithFormat:@""];
                [alert setAlertStyle:NSCriticalAlertStyle];
                if ([alert runModal] == NSAlertDefaultReturn)
                {
                    [self cancelProxyLoad];
                }
                else
                {
                    [self failProxyLoad];
                }
            }
            else
            {
                [self failProxyLoad];
            }
        }
        else
        {
            proxyDict[@"proxy"] = [[HTTPProxy alloc] initWithString:proxyValue];
            [self finishProxyLoad];
        }
    }
    else
    {
        NSLog(@"INFO: No proxy to load");
        [_logger addToLog:@"INFO: No proxy to load"];
        [self finishProxyLoad];
    }
}

- (void)cancelProxyLoad
{
    [self returnFromProxyLoadWithError:[NSError errorWithDomain:@"Proxy" code:kProxyLoadCancelled userInfo:@{NSLocalizedDescriptionKey: @"Proxy Load Cancelled"}]];
}

- (void)failProxyLoad
{
    [self returnFromProxyLoadWithError:[NSError errorWithDomain:@"Proxy" code:kProxyLoadFailed userInfo:@{NSLocalizedDescriptionKey: @"Proxy Load Failed"}]];
}

- (void)finishProxyLoad
{
    NSLog(@"INFO: Proxy load complete.");
    [_logger addToLog:@"INFO: Proxy load complete."];
    if (proxyDict[@"proxy"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"TestProxy"])
    {
        [self testProxyOnLoad];
        return;
    }
    [self returnFromProxyLoadWithError:nil];
}

- (void)testProxyOnLoad
{
    HTTPProxy *proxy = proxyDict[@"proxy"];
    
    if (proxy)
    {
        if (!proxy.host || [proxy.host length] == 0 || [proxy.host rangeOfString:@"(null)"].location != NSNotFound)
        {
            NSLog(@"WARNING: Invalid proxy host: address=%@ length=%ld", proxy.host, [proxy.host length]);
            [_logger addToLog:[NSString stringWithFormat:@"WARNING: Invalid proxy host: address=%@ length=%ld", proxy.host, [proxy.host length]]];
            if (!currentIsSilent)
            {
                NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid proxy host.\nDownloads may fail.\nDo you wish to continue?"
                                                 defaultButton:@"No"
                                               alternateButton:@"Yes"
                                                   otherButton:nil
                                     informativeTextWithFormat:@"Invalid proxy host: address=[%@] length=%ld", proxy.host, [proxy.host length]];
                [alert setAlertStyle:NSCriticalAlertStyle];
                if ([alert runModal] == NSAlertDefaultReturn)
                    [self cancelProxyLoad];
                else
                    [self failProxyTest];
            }
            else
            {
                [self failProxyLoad];
            }
            return;
        }
        NSString *testURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"ProxyTestURL"];
        if (!testURL)
            testURL = @"http://www.google.com";
        
        NSURLSessionConfiguration *sessionConfiguration = [[NSURLSessionConfiguration alloc] init];
        sessionConfiguration.connectionProxyDictionary = proxy.connectionProxyDictionary;
        sessionConfiguration.timeoutIntervalForRequest = 30.0;
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:testURL]
                                                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                         [self proxyTestDidFinish:(NSHTTPURLResponse *)response error:error usingConfiguration:sessionConfiguration];
                                                                     }];
        [dataTask resume];
        
        [self updateProxyLoadStatus:YES message:[NSString stringWithFormat:@"Testing proxy (may take up to %ld seconds)...", (NSInteger)sessionConfiguration.timeoutIntervalForRequest]];
        NSLog(@"INFO: Testing proxy (may take up to %ld seconds)...", (NSInteger)sessionConfiguration.timeoutIntervalForRequest);
        [_logger addToLog:[NSString stringWithFormat:@"INFO: Testing proxy (may take up to %ld seconds)...", (NSInteger)sessionConfiguration.timeoutIntervalForRequest]];
    }
    else
    {
        NSLog(@"INFO: No proxy to test");
        [_logger addToLog:@"INFO: No proxy to test"];
        [self finishProxyTest];
    }
}

- (void)proxyTestDidFinish:(NSHTTPURLResponse *)response error:(NSError *)error usingConfiguration:(NSURLSessionConfiguration *)configuration
{
    if (response.statusCode != 200)
    {
        NSLog(@"WARNING: Proxy failed to load test page: %@", response.URL);
        [_logger addToLog:[NSString stringWithFormat:@"WARNING: Proxy failed to load test page: %@", response.URL]];
        if (!currentIsSilent)
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Proxy failed to load test page.\nDownloads may fail.\nDo you wish to continue?"
                                             defaultButton:@"No"
                                           alternateButton:@"Yes"
                                               otherButton:nil
                                 informativeTextWithFormat:@"Failed to load %@ within %ld seconds\nUsing proxy: %@\nError: %@", response.URL, (NSInteger)configuration.timeoutIntervalForRequest, [proxyDict[@"proxy"] url], (error ? [error localizedDescription] : @"Unknown error")];
            [alert setAlertStyle:NSCriticalAlertStyle];
            if ([alert runModal] == NSAlertDefaultReturn)
                [self cancelProxyLoad];
            else
                [self failProxyTest];
        }
        else
        {
            [self failProxyTest];
        }
    }
    else
    {
        [self finishProxyTest];
    }
}

- (void)failProxyTest
{
    [self returnFromProxyLoadWithError:[NSError errorWithDomain:@"Proxy" code:kProxyLoadFailed userInfo:@{NSLocalizedDescriptionKey: @"Proxy Test Failed"}]];
}

- (void)finishProxyTest
{
    NSLog(@"INFO: Proxy test complete.");
    [_logger addToLog:@"INFO: Proxy test complete."];
    [self returnFromProxyLoadWithError:nil];
}

- (void)returnFromProxyLoadWithError:(NSError *)error
{
    if (proxyDict[@"proxy"])
    {
        NSLog(@"INFO: Using proxy: %@", [proxyDict[@"proxy"] url]);
        [_logger addToLog:[NSString stringWithFormat:@"INFO: Using proxy: %@", [proxyDict[@"proxy"]url]]];
    }
    else
    {
        NSLog(@"INFO: No proxy will be used");
        [_logger addToLog:@"INFO: No proxy will be used"];
    }
    [self updateProxyLoadStatus:NO message:nil];
    if (error) {
        proxyDict[@"error"] = error;
    }
    _completionHandler(proxyDict);
}

- (void)updateProxyLoadStatus:(BOOL)working message:(NSString *)message
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if (working)
    {
        userInfo[@"indeterminate"] = @YES;
        userInfo[@"animated"] = @YES;
        [nc postNotificationName:@"setPercentage" object:self userInfo:userInfo];
        [nc postNotificationName:@"setCurrentProgress" object:self userInfo:@{@"string" : message}];
    }
    else
    {
        userInfo[@"indeterminate"] = @NO;
        userInfo[@"animated"] = @NO;
        [nc postNotificationName:@"setPercentage" object:self userInfo:userInfo];
        [nc postNotificationName:@"setCurrentProgress" object:self userInfo:@{@"string" : @""}];
    }
}

@end
