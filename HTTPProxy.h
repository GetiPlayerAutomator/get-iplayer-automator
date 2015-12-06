//
//  HTTPProxy.h
//  Get_iPlayer GUI
//

#import <Foundation/Foundation.h>

@interface HTTPProxy : NSObject
{
    NSURL *url;
    NSString *type;
    NSString *host;
    NSNumber *port;
    NSString *user;
    NSString *password;
}

- (id)initWithURL:(NSURL *)aURL;
- (id)initWithString:(NSString *)aString;

@property (readonly, copy) NSURL *url;
@property (readonly, copy) NSString *type;
@property (readonly, copy) NSString *host;
@property (readonly, copy) NSNumber *port;
@property (readonly, copy) NSString *user;
@property (readonly, copy) NSString *password;
@property (readonly) NSDictionary *connectionProxyDictionary;
@end
