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
@property (nonatomic, assign) BOOL isWatchMode;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL hasFinished;
@property (nonatomic, assign) NSTimeInterval lastShowTime;
@property (nonatomic, strong) SplashWindow *window;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSTimer *watchdogTimer;
@property (nonatomic, strong) id keyMonitor;
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

- (NSString *)find550cHtmlPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *bundleHtml = [[NSBundle mainBundle] pathForResource:@"550c" ofType:@"html"];
    if (bundleHtml && [fm fileExistsAtPath:bundleHtml]) return bundleHtml;
    
    NSString *pluginHtml = [NSHomeDirectory() stringByAppendingPathComponent:@".gemini/config/plugins/antigravity-550c/550c.html"];
    if ([fm fileExistsAtPath:pluginHtml]) return pluginHtml;

    NSString *appHtml = @"/Applications/Antigravity 550C.app/Contents/Resources/550c.html";
    if ([fm fileExistsAtPath:appHtml]) return appHtml;

    NSString *hansHtml = @"/Applications/Antigravity 中文.app/Contents/Resources/550c.html";
    if ([fm fileExistsAtPath:hansHtml]) return hansHtml;

    NSString *currHtml = [fm.currentDirectoryPath stringByAppendingPathComponent:@"550c.html"];
    if ([fm fileExistsAtPath:currHtml]) return currHtml;

    return nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.targetAppURL = [self determineTargetAppURL];
    
    if (self.isWatchMode) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        NSLog(@"[Antigravity 550C] Watcher daemon active. Monitoring Antigravity launch events...");
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
            selector:@selector(handleAppWillLaunch:)
            name:NSWorkspaceWillLaunchApplicationNotification
            object:nil];
    } else {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [self prewarmTargetApp];
        [self showSplashWindow];
    }
}

- (void)handleAppWillLaunch:(NSNotification *)note {
    NSRunningApplication *app = note.userInfo[NSWorkspaceApplicationKey];
    NSString *bid = app.bundleIdentifier;
    if (!bid) return;
    
    if ([bid isEqualToString:@"com.google.antigravity"] ||
        [bid isEqualToString:@"com.antigravity.hans.wrapper.antigravity"] ||
        [bid isEqualToString:@"com.antigravity.550c.launcher"]) {
        
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        if (self.isShowing || (now - self.lastShowTime < 15.0)) {
            return;
        }
        self.lastShowTime = now;
        NSLog(@"[Antigravity 550C Watcher] Antigravity launching (%@). Triggering instant 550C splash...", bid);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showSplashWindow];
        });
    }
}

- (void)showSplashWindow {
    if (self.isShowing) return;
    self.isShowing = YES;
    self.hasFinished = NO;
    
    NSScreen *screen = [NSScreen mainScreen] ?: [NSScreen screens].firstObject;
    NSRect winRect = screen ? screen.frame : NSMakeRect(0, 0, 1920, 1080);
    
    self.window = [[SplashWindow alloc] initWithContentRect:winRect
                                                  styleMask:NSWindowStyleMaskBorderless
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
    self.window.backgroundColor = [NSColor colorWithCalibratedRed:5.0/255.0 green:4.0/255.0 blue:3.0/255.0 alpha:1.0];
    self.window.opaque = YES;
    self.window.hasShadow = NO;
    self.window.level = NSScreenSaverWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:@"splash"];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = contentController;
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    
    self.webView = [[WKWebView alloc] initWithFrame:winRect configuration:config];
    self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.webView setValue:@NO forKey:@"drawsBackground"];
    self.webView.wantsLayer = YES;
    
    NSString *htmlPath = [self find550cHtmlPath];
    if (htmlPath) {
        NSURL *fileURL = [NSURL fileURLWithPath:htmlPath];
        [self.webView loadFileURL:fileURL allowingReadAccessToURL:[fileURL URLByDeletingLastPathComponent]];
    } else {
        NSLog(@"[Antigravity 550C] 550c.html not found!");
        [self finishSplash];
        return;
    }
    
    self.window.contentView = self.webView;
    self.window.alphaValue = 1.0;
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    
    // Keyboard monitor for Escape key (keyCode 53)
    __weak typeof(self) weakSelf = self;
    if (self.keyMonitor) {
        [NSEvent removeMonitor:self.keyMonitor];
        self.keyMonitor = nil;
    }
    self.keyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
        if (event.keyCode == 53) {
            [weakSelf finishSplash];
            return nil;
        }
        return event;
    }];
    
    // Watchdog timer: dismiss after 26.0 seconds maximum to allow full sequence to complete
    if (self.watchdogTimer) {
        [self.watchdogTimer invalidate];
    }
    self.watchdogTimer = [NSTimer scheduledTimerWithTimeInterval:26.0 repeats:NO block:^(NSTimer *timer) {
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
    NSArray<NSRunningApplication *> *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.google.antigravity"];
    if (apps.count == 0) {
        apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.antigravity.hans.wrapper.antigravity"];
    }
    if (apps.count > 0) {
        [apps.firstObject activateWithOptions:NSApplicationActivateAllWindows];
        return;
    }
    if (!self.isWatchMode && self.targetAppURL) {
        NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
        config.activates = YES;
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:self.targetAppURL
                                              configuration:config
                                          completionHandler:nil];
    }
}

- (void)finishSplash {
    if (self.hasFinished) return;
    self.hasFinished = YES;
    
    [self.watchdogTimer invalidate];
    self.watchdogTimer = nil;
    
    if (self.keyMonitor) {
        [NSEvent removeMonitor:self.keyMonitor];
        self.keyMonitor = nil;
    }
    
    // Bring Antigravity to front
    [self activateTargetApp];
    
    // Smooth fade-out transition
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.70;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        self.window.animator.alphaValue = 0.0;
    } completionHandler:^{
        [self.window orderOut:nil];
        self.window = nil;
        self.webView = nil;
        self.isShowing = NO;
        
        if (!self.isWatchMode) {
            [NSApp terminate:nil];
        }
    }];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        
        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "--watch") == 0) {
                delegate.isWatchMode = YES;
            }
        }
        
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
