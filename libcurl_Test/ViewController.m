//
//  ViewController.m
//  libcurl_Test
//
//  Created by      on 16/3/10.
//  Copyright © 2016年     . All rights reserved.
//

#import "ViewController.h"
#import "curl/curl.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *curlImageView;
@property(nonatomic, strong)NSMutableData *imageData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.curlImageView.backgroundColor = [UIColor blueColor];
    self.imageData = [[NSMutableData alloc]init];
    
    _curl = curl_easy_init();
    [NSThread detachNewThreadSelector:@selector(callCurl) toTarget:self withObject:nil];
}

- (double)getDownloadFileSize:(NSString *)url
{
    double  fileSize = 0.0;
    curl_easy_setopt(_curl, CURLOPT_URL, [url UTF8String]);
    curl_easy_setopt(_curl, CURLOPT_HEADER, 1);
    curl_easy_setopt(_curl, CURLOPT_NOBODY, 1);
    if (curl_easy_perform(_curl) == CURLE_OK) {
        curl_easy_getinfo(_curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &fileSize);
    }else{
        fileSize = -1;
    }
    return fileSize;
}

- (double)getLocalFileSize:(NSString *)filePath
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = [[NSError alloc]init];
    if ([manager fileExistsAtPath:filePath]) {
        return (double)[[manager attributesOfItemAtPath:filePath error:(&error)] fileSize];
    }else{
        return  -1;
    }
}



- (void)callCurl
{
    double localfileLen = 0.0;
    double downloadFileLen = 0.0;
    NSString *url = @"http://img.blog.csdn.net/20160317170019402?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center";
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imagePath = [documentPath stringByAppendingPathComponent:@"get.gif"];
    localfileLen = [self getLocalFileSize:imagePath];
    //downloadFileLen = [self getDownloadFileSize:url];
    NSLog(@"---line:%d---localfileLen:%f", __LINE__, localfileLen);
    NSLog(@"---line:%d---downloadFileLen:%f", __LINE__, downloadFileLen);
    

    curl_easy_setopt(_curl, CURLOPT_URL, [url UTF8String]);//4M
    curl_easy_setopt(_curl, CURLOPT_TIMEOUT, 20);        //设置超时
    //curl_easy_setopt(_curl, CURLOPT_RANGE, "0-10000");
    if (localfileLen != -1.00) {
        curl_easy_setopt(_curl, CURLOPT_RESUME_FROM, (long)localfileLen);     //用于断点
    }
    curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, imageViewCallback);
    curl_easy_setopt(_curl, CURLOPT_WRITEDATA, self);
    CURLcode errorCode = curl_easy_perform(_curl);
    NSLog(@"--line:%d----errorCode:%d", __LINE__, errorCode);
    const char* pError = curl_easy_strerror(errorCode);
    NSString *errorStr =[[NSString alloc]initWithUTF8String:pError];
    NSLog(@"--line:%d---->>>errosStr:%@", __LINE__,errorStr);
    
    UIImage *image = [UIImage imageWithData:_imageData];
    if (image != nil) {
        [self performSelectorOnMainThread:@selector(setImage:) withObject:nil waitUntilDone:YES];
    }
}


/**
 * 设置imageview的图片
 */
- (void)setImage:(UIImage *)image
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imagePath = [documentPath stringByAppendingPathComponent:@"get.gif"];
    NSLog(@"--line:%d---Path:%@------imagePath:%@", __LINE__, documentPath, imagePath);
    //self.curlImageView.image = image;
}

size_t imageViewCallback(char *ptr, size_t size, size_t nmemb, void *userdata)
{
    const size_t sizeInBytes = size*nmemb;
//    ViewController *vc = (__bridge ViewController *)userdata;
    NSData *data = [[NSData alloc]initWithBytes:ptr length:sizeInBytes];
    NSLog(@"--->>line:%d,data:%@", __LINE__, data);
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [documentPath stringByAppendingPathComponent:@"get.gif"];
    NSLog(@"--line:%d---Path:%@------filePath:%@", __LINE__, documentPath, filePath);
    NSFileManager *manager  = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }else{
        [data writeToFile:filePath atomically:YES];
    }
    return sizeInBytes;
}


- (void)dealloc
{
    curl_easy_cleanup(_curl);
}

- (void)test
{
    NSString *path = [[[NSBundle mainBundle]bundlePath] stringByAppendingString:@"/index.html"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *htmlPath = [documentPath stringByAppendingPathComponent:@"111.html"];
    NSLog(@"--line:%d---Path:%@--->>>htmlPath:%@", __LINE__, documentPath, htmlPath);
    [data writeToFile:htmlPath atomically:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
