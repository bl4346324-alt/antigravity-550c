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
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *hansPath = @"/Applications/Antigravity 中文.app";
    NSString *stdPath = @"/Applications/Antigravity.app";
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // If running inside Antigravity 中文.app, launch the actual Antigravity.app
    if ([bundlePath containsString:@"Antigravity 中文.app"]) {
        if ([fm fileExistsAtPath:stdPath]) {
            return [NSURL fileURLWithPath:stdPath];
        }
    }
    
    if ([fm fileExistsAtPath:hansPath] && ![bundlePath isEqualToString:hansPath]) {
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
    
    // 2. Setup centered high-tech terminal window (avoiding full-screen stretch)
    NSScreen *screen = [NSScreen mainScreen] ?: [NSScreen screens].firstObject;
    NSRect visibleFrame = screen ? screen.visibleFrame : NSMakeRect(0, 0, 1920, 1080);
    
    CGFloat targetW = 1100.0;
    CGFloat targetH = 680.0;
    if (visibleFrame.size.width < targetW + 40.0) targetW = visibleFrame.size.width - 40.0;
    if (visibleFrame.size.height < targetH + 60.0) targetH = visibleFrame.size.height - 60.0;
    
    CGFloat originX = visibleFrame.origin.x + (visibleFrame.size.width - targetW) / 2.0;
    CGFloat originY = visibleFrame.origin.y + (visibleFrame.size.height - targetH) / 2.0;
    NSRect winRect = NSMakeRect(originX, originY, targetW, targetH);
    
    self.window = [[SplashWindow alloc] initWithContentRect:winRect
                                                  styleMask:NSWindowStyleMaskBorderless
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
    self.window.backgroundColor = [NSColor clearColor];
    self.window.opaque = NO;
    self.window.hasShadow = YES;
    self.window.level = NSFloatingWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    
    // 3. Setup WebKit View
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"splash"];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = contentController;
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    
    self.webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, targetW, targetH)
                                      configuration:config];
    self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.webView setValue:@NO forKey:@"drawsBackground"];
    self.webView.wantsLayer = YES;
    self.webView.layer.cornerRadius = 12.0;
    self.webView.layer.masksToBounds = YES;
    self.webView.layer.borderColor = [NSColor colorWithRed:232.0/255.0 green:160.0/255.0 blue:32.0/255.0 alpha:0.35].CGColor;
    self.webView.layer.borderWidth = 1.0;
    
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
