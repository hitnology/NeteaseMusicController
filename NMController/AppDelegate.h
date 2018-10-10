//
//  AppDelegate.h
//  NMController
//
//  Created by dillon on 2018/10/8.
//  Copyright © 2018 dillon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GCDAsyncSocket;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSNetServiceDelegate> {
//    NSStatusItem *playItem;
//    NSStatusItem *nextItem;
//    NSStatusItem *previousItem;
//    NSStatusItem *likeItem;
    NSStatusItem *statusItem;
    
    NSNetService *netService;
    GCDAsyncSocket *asyncSocket;
    NSMutableArray *connectedSockets;
}

@end

