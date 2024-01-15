//
//  YKSWalkthroughCardVC.m
//  YikesGuestApp
//
//  Created by Manny Singh on 10/7/15.
//  Copyright © 2015 yikes. All rights reserved.
//

#import "YKSWalkthroughCardVC.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface YKSWalkthroughCardVC ()

@property (strong, nonatomic) MPMoviePlayerController *moviePlayer;

@end

@implementation YKSWalkthroughCardVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.greenBackgroundView.backgroundColor = [UIColor clearColor];
    
    
    if (self.peaceOfMindVideoContainerView) {
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        
        self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"peace_of_mind_animation" ofType:@"mp4"]]];
        [self.moviePlayer.view setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
        [self.moviePlayer setControlStyle:MPMovieControlStyleNone];
        [self.moviePlayer setScalingMode:MPMovieScalingModeAspectFit];
        self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
        self.moviePlayer.shouldAutoplay = NO;
        self.moviePlayer.allowsAirPlay = NO;
        [self.moviePlayer prepareToPlay];
        [self.peaceOfMindVideoContainerView addSubview:self.moviePlayer.view];
        
        self.moviePlayer.view.backgroundColor = [UIColor clearColor];
        self.moviePlayer.backgroundView.backgroundColor = [UIColor clearColor];
        for(UIView *subView in self.moviePlayer.view.subviews) {
            subView.backgroundColor = [UIColor clearColor];
        }
        
        id views = @{ @"player": self.moviePlayer.view };
        [self.peaceOfMindVideoContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[player]|"
                                                                                                   options:0
                                                                                                   metrics:nil
                                                                                                     views:views]];
        
        [self.peaceOfMindVideoContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[player]|"
                                                                                                   options:0
                                                                                                   metrics:nil
                                                                                                     views:views]];
        
        [self.moviePlayer play];
        
    }
    
}

- (IBAction)dismissAnyModel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
