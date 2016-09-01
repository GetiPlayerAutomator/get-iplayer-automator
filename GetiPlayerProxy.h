//
//  GetiPlayerProxy.h
//  Get_iPlayer GUI
//
//  Created by Thomas Willson on 8/7/14.
//
//

#import <Foundation/Foundation.h>
#import "HTTPProxy.h"
#import "LogController.h"

@interface GetiPlayerProxy : NSObject {
    //Proxy
    LogController *_logger;
    NSMutableDictionary *proxyDict;
    BOOL currentIsSilent;
    
    void (^_completionHandler)(NSDictionary *proxyDictionary);
    
    enum {
        kProxyLoadCancelled = 1,
        kProxyLoadFailed = 2,
        kProxyTestFailed = 3
    };
    
}
- (void)loadProxyInBackgroundWithCompletionHandler:(void (^)(NSDictionary *proxyDictionary))completionHandler silently:(BOOL)silent;
- (id)initWithLogger:(LogController *)logger;

@end
