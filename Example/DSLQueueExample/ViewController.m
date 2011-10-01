//
//  ViewController.m
//  DSLQueueExample
//
//  Created by Pete Callaway on 01/10/2011.
//  Copyright (c) 2011 Dative Studios. All rights reserved.
//

#import "DownloadTwitterImageOperation.h"
#import "DownoadTwitterTimelineOperation.h"
#import "ViewController.h"


@interface ViewController()

@property (nonatomic, strong) DSLQueue *queue;
@property (nonatomic, strong) NSArray *tweets;
@property (nonatomic, strong) NSMutableDictionary *tweetImages;

@end


@implementation ViewController

@synthesize queue=__queue;
@synthesize tableView=__tableView;
@synthesize tweets=__tweets;
@synthesize tweetImages=__tweetImages;


#pragma mark - Designated initialiser

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        self.queue = [[DSLQueue alloc] init];
        self.tweetImages = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.tableView = nil;
    self.tweetImages = [[NSMutableDictionary alloc] init];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    DownoadTwitterTimelineOperation *newOperation = [[DownoadTwitterTimelineOperation alloc] init];

    __weak ViewController *blockSelf = self; 
    __weak DownoadTwitterTimelineOperation *blockOperation = newOperation;
    
    [newOperation addCompletionBlock:^(DSLOperation *dslOperation) {
        blockSelf.tweets = blockOperation.tweets;
        [blockSelf.tableView reloadData];
    }];
    
    [self.queue addOperation:newOperation];
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* const ViewControllerTableViewCellIdentifier = @"ViewControllerTableViewCellIdentifier";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ViewControllerTableViewCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ViewControllerTableViewCellIdentifier];
    }
    
    NSDictionary *tweet = [self.tweets objectAtIndex:indexPath.row];
    cell.textLabel.text = [tweet valueForKey:@"text"];
    cell.detailTextLabel.text = [tweet valueForKeyPath:@"user.name"];
    
    NSString *userName = [tweet valueForKeyPath:@"user.screen_name"];
    UIImage *image = [self.tweetImages objectForKey:userName];
    
    if (image != nil) {
        cell.imageView.image = image;
    }
    else {
        cell.imageView.image = nil;
        
        NSURL *imageURL = [NSURL URLWithString:[tweet valueForKeyPath:@"user.profile_image_url"]];
        DownloadTwitterImageOperation *newOperation = [[DownloadTwitterImageOperation alloc] initWithURL:imageURL];
        
        __weak ViewController *blockSelf = self; 
        __weak DownloadTwitterImageOperation *blockOperation = newOperation;

        [newOperation addCompletionBlock:^(DSLOperation *dslOperation) {
            UIImage *image = [[UIImage alloc] initWithData:blockOperation.imageData];
            if (image != nil) {
                [blockSelf.tweetImages setObject:image forKey:userName];
                [blockSelf.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }];
        
        [self.queue addOperation:newOperation];
    }
    
    return cell;
}

@end
