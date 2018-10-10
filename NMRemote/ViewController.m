//
//  ViewController.m
//  NMRemote
//
//  Created by dillon on 2018/10/10.
//  Copyright © 2018 dillon. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    [netServiceBrowser setDelegate:(id<NSNetServiceBrowserDelegate>)self];
    [netServiceBrowser searchForServicesOfType:@"_YourServiceName._tcp." inDomain:@"local."];
    serverArray = [NSMutableArray new];
    serverAddresses = [NSMutableArray new];
}

#pragma mark - Bonjour
- (void)netServiceBrowser:(NSNetServiceBrowser *)sender didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
//    if (netService.port == 8898) {
    if ([serverArray containsObject:netService]) {
        return;
    }
    NSLog(@"DidFindService: %@", [netService name]);
    [serverArray addObject:netService];
    [self.tableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    NSLog(@"DidRemoveService: %@", [netService name]);
    if ([serverArray containsObject:netService]) {
        [serverArray removeObject:netService];
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender {
    NSLog(@"DidStopSearch");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"DidNotResolve");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"DidResolve: %@", [sender addresses]);
    if (asyncSocket == nil) {
        asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id<GCDAsyncSocketDelegate>)self delegateQueue:dispatch_get_main_queue()];
    }
    serverAddresses = [[sender addresses] mutableCopy];
    [self connectToNextAddress];
//    }
}

- (void)connectToNextAddress {
    BOOL done = NO;
    while (!done && ([serverAddresses count] > 0)) {
        NSData *addr;
        if (YES) {
            addr = [serverAddresses objectAtIndex:0];
            [serverAddresses removeObjectAtIndex:0];
        }
        else {
            addr = [serverAddresses lastObject];
            [serverAddresses removeLastObject];
        }
        
        NSLog(@"Attempting connection to %@", addr);
        NSError *err = nil;
        if ([asyncSocket connectToAddress:addr error:&err]) {
            done = YES;
        }
        else {
            NSLog(@"Unable to connect: %@", err);
        }
    }
    
    if (!done) {
        NSLog(@"Unable to connect to any resolved address");
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);
    connected = YES;
    [self.tableView cellForRowAtIndexPath:self.indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"SocketDidDisconnect:WithError: %@", err);
    [self.tableView cellForRowAtIndexPath:self.indexPath].accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return serverArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    [cell.textLabel setText:serverArray[indexPath.row].name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSNetService *service = serverArray[indexPath.row];
    if (service) {
        self.indexPath = indexPath;
        NSLog(@"Resolving...");
        serverService = service;
        [serverService setDelegate:self];
        [serverService resolveWithTimeout:5.0];
    }
}

#pragma mark - IBAction
- (IBAction)playButtonTouched:(id)sender {
    NSData *data = [@"musicToggle" dataUsingEncoding:NSUTF8StringEncoding];
    [asyncSocket writeData:data withTimeout:10 tag:0];
    NSLog(@"posted");
}

- (IBAction)nextButtonTouched:(id)sender {
    NSData *data = [@"musicNext" dataUsingEncoding:NSUTF8StringEncoding];
    [asyncSocket writeData:data withTimeout:10 tag:0];
    NSLog(@"posted");
}

- (IBAction)previousButtonTouched:(id)sender {
    NSData *data = [@"musicPrevious" dataUsingEncoding:NSUTF8StringEncoding];
    [asyncSocket writeData:data withTimeout:10 tag:0];
    NSLog(@"posted");
}

- (IBAction)likeButtonTouched:(id)sender {
    NSData *data = [@"musicLike" dataUsingEncoding:NSUTF8StringEncoding];
    [asyncSocket writeData:data withTimeout:10 tag:0];
    NSLog(@"posted");
}

@end
