//
//  GitHubOAuthController.m
//
//  Created by Daniel Khamsing on 4/29/15.
//  Copyright (c) 2015 dkhamsing. All rights reserved.
//

#import "GitHubOAuthController.h"

#ifdef GITHUB_OAUTH_ENABLE_1PASSWORD
#import "OnePasswordExtension.h"
#endif

NSString *gh_url_authorize = @"https://github.com/login/oauth/authorize";
NSString *gh_url_token = @"https://github.com/login/oauth/access_token";

NSString *gh_title = @"Loading";

NSString *gh_post = @"POST";
NSString *gh_application_json = @"application/json";

@interface GitHubOAuthController () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIView *spinnerView;

@property (nonatomic, strong) UIBarButtonItem *closeButton;
@property (nonatomic) BOOL modal;

#ifdef GITHUB_OAUTH_ENABLE_1PASSWORD
@property (nonatomic, strong) UIBarButtonItem *onePasswordButton;
#endif

@property (nonatomic, strong) NSString *clientSecret;
@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSString *redirectUri;
@property (nonatomic, strong) NSString *scope;

@property (nonatomic, copy) void (^success)(NSString *, NSDictionary *);
@property (nonatomic, copy) void (^failure)(NSError *);

@end

@implementation GitHubOAuthController

- (instancetype)initWithClientId:(NSString *)clientId clientSecret:(NSString *)clientSecret scope:(NSString *)scope success:(void (^)(NSString *, NSDictionary *))success failure:(void (^)(NSError *))failure {
    self = [super init];
    
    // Init
    self.closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(gh_close)];
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.spinnerView = [[UIView alloc] init];
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

#ifdef GITHUB_OAUTH_ENABLE_1PASSWORD
    if ([[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
        NSBundle *onepasswordExtensionResourcesBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[OnePasswordExtension class]] pathForResource:@"OnePasswordExtensionResources" ofType:@"bundle"]];
        UIImage *image = [UIImage imageNamed:@"onepassword-navbar" inBundle:onepasswordExtensionResourcesBundle compatibleWithTraitCollection:nil];
        self.onePasswordButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(fillUsing1Password:)];
    }
#endif

    // Subviews
    [self.view addSubview:self.webView];
    [self.view addSubview:self.spinnerView];
    [self.spinnerView addSubview:indicatorView];
    
    // Setup
    [self configureForSafariViewControllerWithClientId:clientId clientSecret:clientSecret redirectUri:@"" scope:scope];
    self.success = success;
    self.failure = failure;
    self.title = gh_title;
    self.webView.delegate = self;
    self.spinnerView.backgroundColor = [UIColor blackColor];
    self.spinnerView.alpha = 0;
    [indicatorView startAnimating];
    [self.webView loadRequest: [NSURLRequest requestWithURL:self.authUrl]];
    self.view.tintColor = self.presentingViewController.view.tintColor;
    
    // Layout
    indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin |UIViewAutoresizingFlexibleLeftMargin;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.spinnerView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = @{ @"spin":self.spinnerView, };
    NSDictionary *metrics = nil;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[spin]|" options:0 metrics:metrics views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[spin]|" options:0 metrics:metrics views:views]];

    return self;
}

- (void)showModalFromController:(UIViewController *)controller {
    self.modal = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
    [controller presentViewController:navigationController animated:YES completion:nil];
    
    self.navigationItem.rightBarButtonItem = self.closeButton;

#ifdef GITHUB_OAUTH_ENABLE_1PASSWORD
    if (self.onePasswordButton) {
        self.navigationItem.leftBarButtonItem = self.onePasswordButton;
    }
#endif
}

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark Safari view controller

- (NSURL *)authUrl
{
    NSString *authUrl = [NSString stringWithFormat:@"%@?redirect_uri=%@&client_id=%@&scope=%@",
                         gh_url_authorize,
                         self.redirectUri,
                         self.clientId,
                         self.scope];
    
    return [NSURL URLWithString:authUrl];
}

- (void)configureForSafariViewControllerWithClientId:(NSString *)clientId clientSecret:(NSString *)clientSecret redirectUri:(NSString *)redirectUri scope:(NSString *)scope;
{
    self.clientId = clientId;
    self.clientSecret = clientSecret;
    self.redirectUri = redirectUri;
    self.scope = [scope stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

- (void)exchangeCodeForAccessTokenInUrl:(NSURL *)url success:(void (^)(NSString *accessToken, NSDictionary *raw))success failure:(void (^)(NSError *error))failure;
{
    NSString *code = ({
        NSString *match = @"?code=";
        NSRange range = [url.absoluteString rangeOfString:match];
        [url.absoluteString substringFromIndex:(range.location + match.length)];
    });
    
    NSDictionary *parameters = @{
                                 @"code" : code,
                                 @"client_id" : self.clientId,
                                 @"client_secret" : self.clientSecret,
                                 @"grant_type" : @"authorization_code"
                                 };
    
    __block NSError *parseError = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&parseError];
    
    NSURL *URL = [NSURL URLWithString:gh_url_token];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:gh_post];
    [request setValue:gh_application_json forHTTPHeaderField:@"Accept"];
    [request setValue:gh_application_json forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%@", @([requestData length])] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if ([indexSet containsIndex:statusCode] && data) {
            parseError = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
            if (dictionary) {
                if (success) {
                    success(dictionary[@"access_token"], dictionary);
                }
            }
            else {
                [self gh_logMessage:[NSString stringWithFormat:@"parse error: %@", parseError.localizedDescription]];
                if (failure) {
                    failure(parseError);
                }
            }
        }
        else {
            [self gh_logMessage:[NSString stringWithFormat:@"connection error: %@", error.localizedDescription]];
            if (failure) {
                failure(error);
            }
        }
    }] resume];
}

#pragma mark - Private

- (void)gh_close {
    self.webView.delegate = nil;
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    
    if (self.modal) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)gh_logMessage:(NSString *)message {
    NSLog(@"%@", [NSString stringWithFormat:@"GitHub OAuth %@", message]);
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([self.title isEqualToString:gh_title]) {
        self.title = @"";
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *match = @"?code=";
    NSRange range = [request.URL.absoluteString rangeOfString:match];
    if (range.location != NSNotFound) {
        self.spinnerView.alpha = 0.4;
        
        [self exchangeCodeForAccessTokenInUrl:request.URL success:^(NSString *accessToken, NSDictionary *raw) {
            [self gh_close];
            
            if (self.success) {
                self.success(accessToken, raw);
            }
        } failure:^(NSError *error) {
            [self gh_close];
            
            if (self.failure) {
                self.failure(error);
            }
        }];
    }
    
    return YES;
}

#pragma mark - 1Password

#ifdef GITHUB_OAUTH_ENABLE_1PASSWORD
- (void)fillUsing1Password:(id)sender {
    [[OnePasswordExtension sharedExtension] fillItemIntoWebView:self.webView forViewController:self sender:sender showOnlyLogins:YES completion:^(BOOL success, NSError *error) {
        // Ignore Code=0 "1Password Extension was cancelled by the user"
        if (!success && error.code != 0) {
            NSLog(@"Failed to fill into webview: <%@>", error);
        }
    }];
}
#endif

@end
