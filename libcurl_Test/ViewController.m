//
//  ViewController.m
//  libcurl_Test
//
//  Created by      on 16/3/10.
//  Copyright © 2016年     . All rights reserved.
//

#import "ViewController.h"
#import "curl/curl.h"

#define TICK NSDate *startTime = [NSDate date]
#define TOCK NSLog(@"Time:%f", -[startTime timeIntervalSinceNow])

#define FileName @"test.gif"
#define DownLoad_Url @"http://img.blog.csdn.net/20160317170019402?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center"
#define FilePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:FileName]

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
    [NSThread detachNewThreadSelector:@selector(proccessDownload) toTarget:self withObject:nil];
}

/**
 *  get download file size
 */
- (double)getDownloadFileSize:(NSString *)url
{
    double  fileSize = 0.0;
    CURL *curlHandle;
    curlHandle = curl_easy_init();
    curl_easy_setopt(curlHandle, CURLOPT_URL, [url UTF8String]);
    curl_easy_setopt(curlHandle, CURLOPT_HEADER, 1);
    curl_easy_setopt(curlHandle, CURLOPT_NOBODY, 1);
    if (curl_easy_perform(curlHandle) == CURLE_OK) {
        curl_easy_getinfo(curlHandle, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &fileSize);
    }else{
        fileSize = -1;
    }
    curl_easy_cleanup(curlHandle);
    return fileSize;
}

/**
 *  get local file size
 */
- (double)getLocalFileSize:(NSString *)filePath
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = [[NSError alloc]init];
    if ([manager fileExistsAtPath:filePath]) {
        return (double)[[manager attributesOfItemAtPath:filePath error:(&error)] fileSize];
    }else{
        return  -1.0;
    }
}


- (void)proccessDownload
{
    double localfileLen = 0.0;
    double downloadFileLen = 0.0;
    NSString *url = DownLoad_Url;

    localfileLen = [self getLocalFileSize:FilePath];
    downloadFileLen = [self getDownloadFileSize:url];
    NSLog(@"---line:%d---localfileLen:%f, downloadFileLen:%f", __LINE__, localfileLen, downloadFileLen);

    curl_easy_setopt(_curl, CURLOPT_URL, [url UTF8String]);
    curl_easy_setopt(_curl, CURLOPT_TIMEOUT, 20);        //设置超时
    //curl_easy_setopt(_curl, CURLOPT_RANGE, "0-10000");
    if (localfileLen != -1.00) {
        curl_easy_setopt(_curl, CURLOPT_RESUME_FROM, (long)localfileLen);     //用于断点
    }
    curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, writeDataCallback);
    curl_easy_setopt(_curl, CURLOPT_WRITEDATA, self);
    CURLcode errorCode = curl_easy_perform(_curl);
    NSLog(@"--line:%d----errorCode:%d", __LINE__, errorCode);
    const char* pError = curl_easy_strerror(errorCode);
    NSString *errorStr =[[NSString alloc]initWithUTF8String:pError];
    NSLog(@"--line:%d---->>>errosStr:%@", __LINE__,errorStr);
    
    UIImage *image = [UIImage imageWithData:_imageData];
    if (image != nil) {
        [self performSelectorOnMainThread:@selector(doSomething:) withObject:nil waitUntilDone:YES];
    }
}


size_t writeDataCallback(char *ptr, size_t size, size_t nmemb, void *userdata)
{
    const size_t sizeInBytes = size*nmemb;
    //ViewController *vc = (__bridge ViewController *)userdata;
    NSData *data = [[NSData alloc]initWithBytes:ptr length:sizeInBytes];
    NSLog(@"--->>line:%d,data:%@", __LINE__, data);
    //NSLog(@"--line:%d---Path:%@------filePath:%@", __LINE__, FilePath);
    NSFileManager *manager  = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:FilePath]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:FilePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }else{
        [data writeToFile:FilePath atomically:YES];
    }
    return sizeInBytes;
}


- (void)doSomething:(UIImage *)image
{
    self.curlImageView.image = image;
}


- (void)dealloc
{
    curl_easy_cleanup(_curl);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
