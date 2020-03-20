//
//  ViewController.m
//  SYMediaPlayerDemo
//
//  Created by RYB_iMAC on 2020/3/15.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "ViewController.h"
#import "SYPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray * itemArray;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    if (!_itemArray)
        _itemArray = [NSMutableArray array];
    else
        [_itemArray removeAllObjects];
    
    NSError *error;
    NSString *entry;
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:documentPath];
    
    while (entry = [directoryEnumerator nextObject]) {
        NSString *path = [documentPath stringByAppendingPathComponent:entry];
        if ([entry hasPrefix:@"."]) {
            [NSFileManager.defaultManager removeItemAtPath:path error:&error];
            continue;
        }
        
        NSDictionary *currentdict = [directoryEnumerator fileAttributes];
        NSString *filetype = [currentdict objectForKey:NSFileType];
        
        if ([filetype isEqualToString:NSFileTypeDirectory]) {
        }
        else if ([entry pathExtension].length > 0) {
            NSString *newPath = [documentPath stringByAppendingPathComponent:entry];
            [_itemArray addObject:[NSURL fileURLWithPath:newPath]];
        }
        else
            NSLog (@"File Name - %@", entry);
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _itemArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [[_itemArray objectAtIndex:indexPath.row] lastPathComponent];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SYPlayerViewController * obj = [[SYPlayerViewController alloc] init];
    obj.selectedURL = [_itemArray objectAtIndex:indexPath.row];
    obj.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:obj animated:YES completion:^{
        ;
    }];
}


@end
