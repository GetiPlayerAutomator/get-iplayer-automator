//
//  HTTPProxy.m
//  Get_iPlayer GUI
//

#import "HTTPProxy.h"

@implementation HTTPProxy

- (id)initWithURL:(NSURL *)aURL
{
    self = [super init];
    url = [aURL copy];
    if ([[[url scheme] lowercaseString] isEqualToString:@"https"])
        type = (NSString *)kCFProxyTypeHTTPS;
    else
        type = (NSString *)kCFProxyTypeHTTP;
    host = [[url host] copy];
    port = [[url port] copy];
    user = [[url user] copy];
    password = [[url password] copy];
    return self;
}

- (id)initWithString:(NSString *)aString
{
    if ([[aString lowercaseString] hasPrefix:@"http://"] || [[aString lowercaseString] hasPrefix:@"https://"])
        return [self initWithURL:[NSURL URLWithString:aString]];
    else
        return [self initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", aString]]];
}

-(NSDictionary *)connectionProxyDictionary
{
    NSMutableDictionary *connectionProxy = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                           (__bridge NSString *)kCFProxyTypeKey: (__bridge NSString *)kCFProxyTypeHTTP,
                                                                                           (__bridge NSString *)kCFProxyHostNameKey: host,
                                                                                        }];
    NSNumber *portTemp;
    if (port) {
        portTemp = port;
    }
    else {
        if ([type isEqualToString:(__bridge NSString *)kCFProxyTypeHTTP]) {
            portTemp = @(80);
        }
        else if([type isEqualToString:(__bridge NSString *)kCFProxyTypeHTTPS]) {
            portTemp = @(443);
        }
        else {
            NSAssert(FALSE, @"Proxy Type should match kCFProxyTypeHTTP or kCFProxyTypeHTTPS!");
        }
    }
    connectionProxy[(__bridge NSString *)kCFProxyPortNumberKey] = portTemp;
    
    if (user) {
        connectionProxy[(__bridge NSString *)kCFProxyUsernameKey] = user;
        connectionProxy[(__bridge NSString *)kCFProxyPasswordKey] = password;
    }
    
    return connectionProxy;
}

@synthesize url;
@synthesize type;
@synthesize host;
@synthesize port;
@synthesize user;
@synthesize password;

@end
