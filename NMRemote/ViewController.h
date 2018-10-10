//
//  ViewController.h
//  NMRemote
//
//  Created by dillon on 2018/10/10.
//  Copyright © 2018 dillon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"

//@class GCDAsyncSocket;

@interface ViewController : UIViewController<NSNetServiceDelegate> {
    NSNetServiceBrowser *netServiceBrowser;
    NSNetService *serverService;
    NSMutableArray<NSNetService *> *serverArray;
    NSMutableArray *serverAddresses;
    GCDAsyncSocket *asyncSocket;
    BOOL connected;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

