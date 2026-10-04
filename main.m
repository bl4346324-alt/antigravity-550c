#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SplashWindow : NSWindow
@end

@implementation SplashWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) SplashWindow *window;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) BOOL hasFinished;
@property (nonatomic, strong) NSTimer *watchdogTimer;
@property (nonatomic, strong) NSURL *targetAppURL;
@end

@implementation AppDelegate

- (NSURL *)determineTargetAppURL {
    NSString *hansPath = @"/Applications/Antigravity 中文.app";
    NSString *stdPath = @"/Applications/Antigravity.app";
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:hansPath]) {
        return [NSURL fileURLWithPath:hansPath];
    }
    if ([fm fileExistsAtPath:stdPath]) {
        return [NSURL fileURLWithPath:stdPath];
    }
    return nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    self.targetAppURL = [self determineTargetAppURL];
    
    // 1. Prewarm Antigravity in background quietly so it is ready when the animation finishes
    [self prewarmTargetApp];
    
    // 2. Setup full screen borderless window
    NSScreen *screen = [NSScreen mainScreen] ?: [NSScreen screens].firstObject;
    NSRect screenFrame = screen ? screen.frame : NSMakeRect(0, 0, 1920, 1080);
    
    self.window = [[SplashWindow alloc] initWithContentRect:screenFrame
                                                  styleMask:NSWindowStyleMaskBorderless
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
    self.window.backgroundColor = [NSColor blackColor];
    self.window.opaque = YES;
    self.window.hasShadow = NO;
    self.window.level = NSFloatingWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    
    // 3. Setup WebKit View
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"splash"];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = contentController;
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    
    self.webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, screenFrame.size.width, screenFrame.size.height)
                                      configuration:config];
    self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.webView setValue:@NO forKey:@"drawsBackground"];
    
    // Locate 550c.html
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"550c" ofType:@"html"];
    if (!htmlPath) {
        htmlPath = [[NSFileManager defaultManager].currentDirectoryPath stringByAppendingPathComponent:@"550c.html"];
    }
    
    if (htmlPath && [[NSFileManager defaultManager] fileExistsAtPath:htmlPath]) {
        NSURL *fileURL = [NSURL fileURLWithPath:htmlPath];
        [self.webView loadFileURL:fileURL allowingReadAccessToURL:[fileURL URLByDeletingLastPathComponent]];
    } else {
        NSLog(@"[Antigravity 550C] 550c.html not found!");
        [self finishSplash];
        return;
    }
    
    self.window.contentView = self.webView;
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    
    // 4. Keyboard monitor for Escape key (keyCode 53)
    __weak typeof(self) weakSelf = self;
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
        if (event.keyCode == 53) {
            [weakSelf finishSplash];
            return nil;
        }
        return event;
    }];
    
    // 5. Watchdog timer: dismiss after 24 seconds maximum
    self.watchdogTimer = [NSTimer scheduledTimerWithTimeInterval:24.0 repeats:NO block:^(NSTimer *timer) {
        [weakSelf finishSplash];
    }];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"splash"]) {
        [self finishSplash];
    }
}

- (void)prewarmTargetApp {
    if (!self.targetAppURL) return;
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    config.activates = NO;
    config.addsToRecentItems = NO;
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:self.targetAppURL
                                          configuration:config
                                      completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error) {
            NSLog(@"[Antigravity 550C] Prewarm notice: %@", error.localizedDescription);
        }
    }];
}

- (void)activateTargetApp {
    if (!self.targetAppURL) return;
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    config.activates = YES;
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:self.targetAppURL
                                          configuration:config
                                      completionHandler:nil];
}

- (void)finishSplash {
    if (self.hasFinished) return;
    self.hasFinished = YES;
    
    [self.watchdogTimer invalidate];
    self.watchdogTimer = nil;
    
    // Bring Antigravity 中文版 to front
    [self activateTargetApp];
    
    // Smooth fade-out transition
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.45;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        self.window.animator.alphaValue = 0.0;
    } completionHandler:^{
        [self.window orderOut:nil];
        [NSApp terminate:nil];
    }];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
