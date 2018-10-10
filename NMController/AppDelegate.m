//
//  AppDelegate.m
//  NMController
//
//  Created by dillon on 2018/10/8.
//  Copyright © 2018 dillon. All rights reserved.
//

#import "AppDelegate.h"
#import "GCDAsyncSocket.h"

@interface AppDelegate ()<GCDAsyncSocketDelegate> {
    
}

@property (nonatomic, copy) NSString *scriptPath;
@property (weak) IBOutlet NSMenu *contentMenu;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
    
    self.scriptPath = [[NSBundle mainBundle] pathForResource:@"NMScript" ofType:@"scpt"];
    
//    previousItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
//    NSImage *previousImage = [NSImage imageNamed:@"previous"];
//    previousImage.size = NSMakeSize(18.0, 18.0);
//    previousItem.button.tag = 0;
//    previousItem.button.image = previousImage;
//    previousItem.button.target = self;
//    previousItem.button.action = @selector(buttonTouched:);
//    [previousItem.button sendActionOn:(NSEventMaskLeftMouseUp|NSEventMaskRightMouseUp)];
//
//    playItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
//    NSImage *playImage = [NSImage imageNamed:@"play"];
//    playImage.size = NSMakeSize(18.0, 18.0);
//    playItem.button.tag = 1;
//    playItem.button.image = playImage;
//    playItem.button.target = self;
//    playItem.button.action = @selector(buttonTouched:);
//    [playItem.button sendActionOn:(NSEventMaskLeftMouseUp|NSEventMaskRightMouseUp)];
//
//    nextItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
//    NSImage *nextImage = [NSImage imageNamed:@"next"];
//    nextImage.size = NSMakeSize(18.0, 18.0);
//    nextItem.button.tag = 2;
//    nextItem.button.image = nextImage;
//    nextItem.button.target = self;
//    nextItem.button.action = @selector(buttonTouched:);
//    [nextItem.button sendActionOn:(NSEventMaskLeftMouseUp|NSEventMaskRightMouseUp)];
//
//    likeItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
//    NSImage *likeImage = [NSImage imageNamed:@"like"];
//    likeImage.size = NSMakeSize(18.0, 18.0);
//    likeItem.button.tag = 3;
//    likeItem.button.image = likeImage;
//    likeItem.button.target = self;
//    likeItem.button.action = @selector(buttonTouched:);
//    [likeItem.button sendActionOn:(NSEventMaskLeftMouseUp|NSEventMaskRightMouseUp)];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage *statusImage = [NSImage imageNamed:@"remote"];
    statusImage.size = NSMakeSize(18.0, 18.0);
    statusItem.button.image = statusImage;
    statusItem.menu = self.contentMenu;
    
    //CocoaAsyncSocket
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:(id<GCDAsyncSocketDelegate>)self delegateQueue:dispatch_get_main_queue()];
    connectedSockets = [[NSMutableArray alloc] init];
    NSError *err = nil;
    if ([asyncSocket acceptOnPort:8898 error:&err])
    {
        // So what port did the OS give us?
        
        UInt16 port = [asyncSocket localPort];
        netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_YourServiceName._tcp." name:@"" port:port];
        
        [netService setDelegate:self];
        [netService publish];
        
        NSMutableDictionary *txtDict = [NSMutableDictionary dictionaryWithCapacity:2];
        
        [txtDict setObject:@"moo" forKey:@"cow"];
        [txtDict setObject:@"quack" forKey:@"duck"];
        
        NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
        [netService setTXTRecordData:txtData];
    }
    else
    {
        NSLog(@"Error in acceptOnPort:error: -> %@", err);
    }
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Script
- (void)executeCommand:(NSArray *)cmd {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = [pipe fileHandleForReading];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/osascript"];
        [task setArguments:cmd];
        task.currentDirectoryPath = @"/";
        task.standardOutput = pipe;
        
        [task launch];
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        
        NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        NSLog (@"grep returned:\n%@", grepOutput);
    });
}

- (void)buttonTouched:(id)sender {
    NSEvent *event = NSApp.currentEvent;
    NSStatusBarButton *button = sender;
    if (event.type == NSEventTypeLeftMouseUp) {
        switch (button.tag) {
            case 0:
                [self executeCommand:@[self.scriptPath, @"musicPrevious"]];
                break;
            case 1:
                [self executeCommand:@[self.scriptPath, @"musicToggle"]];
                break;
            case 2:
                [self executeCommand:@[self.scriptPath, @"musicNext"]];
                break;
            case 3:
                [self executeCommand:@[self.scriptPath, @"musicLike"]];
                break;
            default:
                break;
        }
    }
//    else {
//        switch (button.tag) {
//            case 0:
//                [previousItem popUpStatusItemMenu:self.contentMenu];
//                break;
//            case 1:
//                [playItem popUpStatusItemMenu:self.contentMenu];
//                break;
//            case 2:
//                [nextItem popUpStatusItemMenu:self.contentMenu];
//                break;
//            case 3:
//                [likeItem popUpStatusItemMenu:self.contentMenu];
//                break;
//            default:
//                break;
//        }
//    }
}

- (IBAction)quitMenu:(id)sender {
    [NSApp terminate:self];
}

#pragma mark - Bonjour
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
    [connectedSockets addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Disconnected %@:%hu", [sock connectedHost], [sock connectedPort]);
    [connectedSockets removeObject:sock];
}

- (void)netServiceDidPublish:(NSNetService *)ns {
    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
              [ns domain], [ns type], [ns name], (int)[ns port]);
}

- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
               [ns domain], [ns type], [ns name], errorDict);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *cmd = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!cmd || cmd.length == 0) {
        [sock readDataWithTimeout:-1 tag:0];
        return;
    }
    if ([cmd isEqualToString:@"musicPrevious"]) {
        [self executeCommand:@[self.scriptPath, @"musicPrevious"]];
    }
    else if ([cmd isEqualToString:@"musicToggle"]) {
        [self executeCommand:@[self.scriptPath, @"musicToggle"]];
    }
    else if ([cmd isEqualToString:@"musicNext"]) {
        [self executeCommand:@[self.scriptPath, @"musicNext"]];
    }
    else if ([cmd isEqualToString:@"musicLike"]) {
        [self executeCommand:@[self.scriptPath, @"musicLike"]];
    }
    [sock readDataWithTimeout:-1 tag:0];
}


@end
