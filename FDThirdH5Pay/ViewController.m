//
//  ViewController.m
//  FDThirdH5Pay
//
//  Created by 1 on 2019/8/30.
//  Copyright © 2019 com.fdyoumi. All rights reserved.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>

@interface ViewController ()<WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *myWebView;

@property (weak, nonatomic) IBOutlet UITextField *tf;


@end

@implementation ViewController

//單獨控制器去除狀態欄
- (BOOL)prefersStatusBarHidden {
    return YES;
}

//嘗試了下在app內介入人保的支付
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self test1];
}

- (IBAction)bb_click:(UIButton *)sender {
    [self.view endEditing:true];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_tf.text]];
}

- (void) test1 {
    self.myWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.myWebView.navigationDelegate = self;
    [self.view addSubview:self.myWebView];
    //加载h5链接 http://m.epicc.com.cn
    NSURL *url = [NSURL URLWithString:@"http://pay.epicc.com.cn/s3-modules-gateway/wx/wxWapPay.action?rdseq=JFCD-SZ201911291815510141873&displayorderinfo=1&sign=7697adb68baf25644f0c849aac5f4fab"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.myWebView loadRequest:request];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSDictionary *headers = [navigationAction.request allHTTPHeaderFields];
    BOOL hasReferer = [headers objectForKey:@"Referer"] != nil;
    
    NSLog(@">>>>>>>>>>>>>%@",navigationAction.request.URL);
    //redirect_url
    NSString *url = navigationAction.request.URL.absoluteString;
    
    /** 嘗試支付回調不會跳到外面去,可惜失敗了,去掉這個redirect_url 還是不行 可能他們做了特殊處理吧 沒有深究 */
    //    if ([url containsString:@"redirect_url"]) {
    //        url = [url componentsSeparatedByString:@"redirect_url"][0];
    //    }
    //
    if ([url containsString:@"weixin://wap/pay"]) {
        NSLog(@"請求地址:%@\n請求頭信息:%@",navigationAction.request.URL,navigationAction.request.allHTTPHeaderFields);
        // 第二步到这 調起微信支付 [NSURL URLWithString:url]
        [self openUrl:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    else if ([url containsString:@"http://pay.epicc.com"] && !hasReferer ) {
        //https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?
        //  发起微信支付后先到这里 我们要做的是设置Referer这个参数,解决回调到safari 浏览器，而不是APP 问题。。（借助URL Scheme 唤起APP 相关知识）
        NSURLRequest *request = navigationAction.request;
        NSMutableURLRequest *newRequest = [[NSMutableURLRequest alloc] init];
        newRequest.allHTTPHeaderFields = request.allHTTPHeaderFields;
#warning scheme 要改
        //Referer这个参数。value值是在H5开发者中心填写的一级域名，不要加 http,记得加://
        //  www.pay.epicc.com://
        //  https://api.fangdongtech.com/ul/
        [newRequest setValue:@"www.api.fangdongtech.com://" forHTTPHeaderField: @"Referer"];
        newRequest.URL = request.URL;
        //修改完成之后加载
        [webView loadRequest:newRequest];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else
    {
        NSString *urlStr = navigationAction.request.URL.absoluteString;
        if ([urlStr hasPrefix:@"alipays://"] || [urlStr hasPrefix:@"alipay://"]) {
            NSURL *alipayURL = [NSURL URLWithString:urlStr];
            [self openUrl:alipayURL];
        }
        // 其他请求正常进行
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void) openUrl:(NSURL *) url {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} completionHandler:^(BOOL success) {
                
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
