//
//  ViewController.m
//  SYMediaPlayerDemo
//
//  Created by RYB_iMAC on 2020/3/15.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "ViewController.h"
#import "SYPlayerViewController.h"
#import "CTAssetsPickerController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController () <UITableViewDelegate, UITableViewDataSource, CTAssetsPickerControllerDelegate>

@property (nonatomic, strong) NSMutableArray * itemArray;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd:)];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self loadDocumentContents];
}

- (void)loadDocumentContents
{
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


#pragma mark - CTAssetsPickerController

- (void)onAdd:(id)sender
{
    CTAssetsPickerController* assetPicker = [[CTAssetsPickerController alloc] init];
    
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
    
    assetPicker.delegate = self;
    assetPicker.showsEmptyAlbums = NO;
    assetPicker.showsCancelButton = YES;
    assetPicker.assetsFetchOptions = fetchOptions;
    assetPicker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:assetPicker animated:YES completion:nil];
}

- (void)assetsPickerControllerDidCancel:(CTAssetsPickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (assets.count == 0)
        return;
    
    dispatch_group_async(dispatch_group_create(), dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.synchronous = YES;
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        [assets enumerateObjectsUsingBlock:^(PHAsset* phAsset, NSUInteger idx, BOOL *stop) {
            PHAssetResource *assetResource;
            NSArray *resourceArray = [PHAssetResource assetResourcesForAsset:phAsset];
            if (resourceArray.count > 0)
                assetResource = (PHAssetResource *)[resourceArray lastObject];
            else
                return;
            
            NSString *fileName = assetResource.originalFilename;
            NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
            unsigned long long fileSize = 0;
            if (@available(iOS 10.0, *))
                fileSize = [[assetResource valueForKey:@"fileSize"] longLongValue];
            
            NSURL *fileURL = [assetResource valueForKey:@"privateFileURL"];
            NSData *assetData = [NSData dataWithContentsOfURL:fileURL];
            if (!assetData)
                assetData = [self getFileContentsDataFromPHAsset:phAsset];
            
            if (assetData.length > 0)
                [assetData writeToFile:filePath atomically:YES];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadDocumentContents];
            [self.tableView reloadData];
        });
    });
}

- (NSData *)getFileContentsDataFromPHAsset:(PHAsset *)phAsset
{
    __block NSData *retData = nil;
    
    if (phAsset.mediaType == PHAssetMediaTypeImage) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
        imageRequestOptions.synchronous = NO;
        imageRequestOptions.networkAccessAllowed = YES;
        imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        imageRequestOptions.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            NSLog(@"%f", progress);
        };
        
        CGSize imageSize = CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight);
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:imageSize
                                                  contentMode:PHImageContentModeAspectFill options:imageRequestOptions
                                                resultHandler:^(UIImage *image, NSDictionary *info) {
            if (image) {
                retData = UIImageJPEGRepresentation(image, 1.f);
            }
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    else if (phAsset.mediaType == PHAssetMediaTypeVideo) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
        videoRequestOptions.networkAccessAllowed = YES;
        videoRequestOptions.version = PHVideoRequestOptionsVersionOriginal;
        videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:videoRequestOptions
                                                  resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            if (avAsset) {
                AVURLAsset *avUrlAsset = (AVURLAsset *)avAsset;
                retData = [NSData dataWithContentsOfURL:avUrlAsset.URL];
            }
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    return retData;
}


#pragma mark - UITableView

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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing)
        return UITableViewCellEditingStyleNone;
    else
        return UITableViewCellEditingStyleDelete;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError* error = nil;
        
        BOOL isDir;
        NSURL *fileURL = [self.itemArray objectAtIndex:indexPath.row];
        BOOL fileExists = [fileManager fileExistsAtPath:fileURL.path isDirectory:&isDir];
        if (isDir || !fileExists)
            return;
        
        if ([fileManager removeItemAtPath:fileURL.path error:&error] == NO){
            NSLog(@"'%@' %@", fileURL.path, error.userInfo[NSUnderlyingErrorKey]);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadDocumentContents];
                [self.tableView reloadData];
            });
        }
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    return @[deleteAction];
}


@end
