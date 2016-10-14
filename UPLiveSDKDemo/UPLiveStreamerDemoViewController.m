//
//  UPLiveStreamerDemoViewController.m
//  UPLiveSDKDemo
//
//  Created by DING FENG on 5/19/16.
//  Copyright © 2016 upyun.com. All rights reserved.
//


#import "UPLiveStreamerDemoViewController.h"
#import "UPLiveStreamerSettingVC.h"
#import "UPLiveStreamerLivingVC.h"
#import <AVFoundation/AVFoundation.h>


@implementation Settings

@end


@interface UPLiveStreamerDemoViewController ()<UITextFieldDelegate>
{
    UITextView *textViewPushUrl;
    UITextView *textViewPlayUrl;
    UITextField *textFieldStreamId;
    
    //摄像头和麦克风权限检查
    BOOL microphoneAvailable;
    BOOL cameraAvailable;
    BOOL microphoneChecked;
    BOOL cameraChecked;
}

@end

@implementation UPLiveStreamerDemoViewController


- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor whiteColor];
    
    //default settings
    Settings *settings = [[Settings alloc] init];
    settings.rtmpServerPushPath = @"rtmp://testlivesdk.v0.upaiyun.com/live/";
    settings.rtmpServerPlayPath = @"rtmp://testlivesdk.b0.upaiyun.com/live/";
    settings.fps = 24;
    settings.filter = YES;
    settings.streamingOn = YES;
    settings.camaraTorchOn = NO;
    settings.camaraPosition = AVCaptureDevicePositionBack;
    settings.videoOrientation = AVCaptureVideoOrientationPortrait;
    settings.level = UPAVCapturerPreset_640x480;
    settings.filterLevel = 3;

    
    self.settings = settings;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 100, 44)];
    label.text = @"输入流id：";
    
    textFieldStreamId = [[UITextField alloc] initWithFrame:CGRectMake(20, 144, 280, 33)];
    textFieldStreamId.delegate = self;
    textFieldStreamId.text = @"test1";
    textFieldStreamId.borderStyle = UITextBorderStyleRoundedRect;
    self.settings.streamId = textFieldStreamId.text;

    UILabel *labelPushUrl = [[UILabel alloc] initWithFrame:CGRectMake(20, 200, 100, 44)];
    labelPushUrl.text = @"推流地址：";
    
    textViewPushUrl = [[UITextView alloc] initWithFrame:CGRectMake(20, 244, 280, 44)];
    textViewPushUrl.editable = NO;
    
    UILabel *labelPlayUrl = [[UILabel alloc] initWithFrame:CGRectMake(20, 288, 100, 44)];
    labelPlayUrl.text = @"播放地址：";
    
    textViewPlayUrl = [[UITextView alloc] initWithFrame:CGRectMake(20, 332, 280, 44)];
    textViewPlayUrl.editable = NO;

    [self.view addSubview:label];
    [self.view addSubview:textFieldStreamId];
    
    [self.view addSubview:labelPushUrl];
    [self.view addSubview:labelPlayUrl];
    [self.view addSubview:textViewPushUrl];
    [self.view addSubview:textViewPlayUrl];

    UIButton *settingsBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 400, 100, 44)];
    [settingsBtn addTarget:self action:@selector(settingsBtn:) forControlEvents:UIControlEventTouchUpInside];
    [settingsBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [settingsBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    settingsBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [settingsBtn setTitle:@"参数设置" forState:UIControlStateNormal];
    
    UIButton *beginBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 66, 100, 44)];
    [beginBtn addTarget:self action:@selector(beginBtn:) forControlEvents:UIControlEventTouchUpInside];
    [beginBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [beginBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    beginBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [beginBtn setTitle:@"开始直播" forState:UIControlStateNormal];
    
    [self.view addSubview:settingsBtn];
    [self.view addSubview:beginBtn];

    [self updateUI];
    
    self.view.backgroundColor = [UIColor whiteColor];
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];
    
    [self.view addGestureRecognizer:tapGesture];
}

- (void)updateUI {
    //计算 upToken
    NSString *upToken = [UPAVCapturer tokenWithKey:@"password"
                                            bucket:@"testlivesdk"
                                        expiration:86400
                                   applicationName:_settings.rtmpServerPushPath.lastPathComponent
                                        streamName:_settings.streamId];
    
    
    textViewPushUrl.text = [NSString stringWithFormat:@"%@%@?_upt=%@", self.settings.rtmpServerPushPath, self.settings.streamId, upToken];
    NSURL *url = [NSURL URLWithString:self.settings.rtmpServerPlayPath relativeToURL:nil];

    NSString *rtmpPlayUrl = [NSString stringWithFormat:@"rtmp://%@/%@/%@?_upt=%@", url.host, _settings.rtmpServerPushPath.lastPathComponent,self.settings.streamId, upToken];
    
    
    upToken = [UPAVCapturer tokenWithKey:@"password"
                                  bucket:@"testlivesdk"
                              expiration:86400
                         applicationName:_settings.rtmpServerPushPath.lastPathComponent
                              streamName:[NSString stringWithFormat:@"%@.m3u8", self.settings.streamId]];

    NSString *hlsPlayUrl = [NSString stringWithFormat:@"http://%@/%@/%@.m3u8?_upt=%@", url.host, _settings.rtmpServerPushPath.lastPathComponent,self.settings.streamId, upToken];
    textViewPlayUrl.text = [NSString stringWithFormat:@"%@ \n%@", rtmpPlayUrl, hlsPlayUrl];
}

- (void)settingsBtn:(UIButton *)sender {
    UPLiveStreamerSettingVC *settingsVC = [[UPLiveStreamerSettingVC alloc] init];
    settingsVC.demoVC = self;
    [self presentViewController:settingsVC animated:YES completion:nil];
}

- (void)tryStartLiving {
    if (!microphoneChecked || !cameraChecked) {
        return ;
    }
    if (!cameraAvailable || !microphoneAvailable) {
        [self errorAlert:@"请开启摄像头和麦克风权限"];
        return;
    }
    
    microphoneChecked = NO;
    cameraChecked = NO;
    cameraAvailable = NO;
    microphoneAvailable = NO;
    UPLiveStreamerLivingVC *livingVC = [[UPLiveStreamerLivingVC alloc] init];
    livingVC.settings = self.settings;
    [self presentViewController:livingVC animated:YES completion:nil];
}

- (void)beginBtn:(UIButton *)sender {
    microphoneChecked = NO;
    cameraChecked = NO;
    cameraAvailable = NO;
    microphoneAvailable = NO;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (!granted) {
                cameraAvailable = NO;
                NSLog(@"需要开启摄像头权限");
            } else {
                cameraAvailable = YES;
                NSLog(@"摄像头权限 ok");
            }
            cameraChecked = YES;
            [self tryStartLiving];
        });
 
    }];
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (!granted) {
                NSLog(@"需要开启麦克风权限");
                microphoneAvailable = NO;
            } else {
                NSLog(@"麦克风权限 ok");
                microphoneAvailable = YES;
            }
            microphoneChecked = YES;
            [self tryStartLiving];
        });

    }];
}

- (void)errorAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^(){
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}



- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    self.settings.streamId = textFieldStreamId.text;
    [self updateUI];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)setSettings:(Settings *)settings {
    _settings = settings;
    [self updateUI];
}

- (void)hideKeyBoard {
    [textFieldStreamId resignFirstResponder];
}



@end
