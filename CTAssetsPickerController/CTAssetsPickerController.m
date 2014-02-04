
/*
 CTAssetsPickerController.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */


#import "CTAssetsPickerController.h"
#import "NSDate+TimeInterval.h"

#define kThumbnailLength    78.0f
#define kThumbnailSize      CGSizeMake(kThumbnailLength, kThumbnailLength)
#define kPopoverContentSize CGSizeMake(320, 480)


#pragma mark - Interfaces

@interface CTAssetsPickerController ()

@property (nonatomic, copy) NSArray *selectedAssets;

- (UIView *)notAllowedView;
- (UIView *)noAssetsView;

@end



@interface CTAssetsGroupViewController : UITableViewController

@end

@interface CTAssetsGroupViewController()

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) NSMutableArray *groups;

@end



@interface CTAssetsViewController : UICollectionViewController

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@end

@interface CTAssetsViewController ()

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, assign) NSInteger numberOfPhotos;
@property (nonatomic, assign) NSInteger numberOfVideos;

@end



@interface CTAssetsGroupViewCell : UITableViewCell

- (void)bind:(ALAssetsGroup *)assetsGroup;

@end

@interface CTAssetsGroupViewCell ()

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@end



@interface CTAssetsViewCell : UICollectionViewCell

- (void)bind:(ALAsset *)asset;

@end

@interface CTAssetsViewCell ()

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *videoImage;
@property (nonatomic, assign) BOOL disabled;

@end



@interface CTAssetsSupplementaryView : UICollectionReusableView

@property (nonatomic, strong) UILabel *sectionLabel;

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos numberOfVideos:(NSInteger)numberOfVideos;

@end

@interface CTAssetsSupplementaryView ()

@end






#pragma mark - CTAssetsPickerController


@implementation CTAssetsPickerController

- (id)init
{
    CTAssetsGroupViewController *groupViewController = [[CTAssetsGroupViewController alloc] init];
    
    if (self = [super initWithRootViewController:groupViewController])
    {
        _assetsFilter               = [ALAssetsFilter allAssets];
        _selectedAssets             = nil;
        _showsCancelButton          = YES;
        
        self.preferredContentSize   = kPopoverContentSize;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Not Allowed / No Assets Views

- (NSString *)deviceModel
{
    return [[UIDevice currentDevice] model];
}

- (BOOL)isCameraDeviceAvailable
{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (UIView *)notAllowedView
{
    UIImageView *padlock    = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CTAssetsPickerLocked"]];
    padlock.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *title          = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.preferredMaxLayoutWidth = 304.0f;
    
    UILabel *message        = [[UILabel alloc] init];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.preferredMaxLayoutWidth = 304.0f;
    
    title.text              = NSLocalizedString(@"This app does not have access to your photos or videos.", nil);
    title.font              = [UIFont boldSystemFontOfSize:17.0];
    title.textColor         = [UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1];
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    message.text            = NSLocalizedString(@"You can enable access in Privacy Settings.", nil);
    message.font            = [UIFont systemFontOfSize:14.0];
    message.textColor       = [UIColor colorWithRed:129.0/255.0 green:136.0/255.0 blue:148.0/255.0 alpha:1];
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    UIView *centerView = [[UIView alloc] init];
    centerView.translatesAutoresizingMaskIntoConstraints = NO;
    [centerView addSubview:padlock];
    [centerView addSubview:title];
    [centerView addSubview:message];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(padlock, title, message);
    
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:padlock attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:centerView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:padlock attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:message attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:padlock attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[padlock]-20-[title]-[message]|" options:0 metrics:nil views:viewsDictionary]];
    
    UIView *view = [[UIView alloc] init];
    [view addSubview:centerView];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];

    return view;
}

- (UIView *)noAssetsView
{
    UILabel *title          = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.preferredMaxLayoutWidth = 304.0f;
    
    UILabel *message        = [[UILabel alloc] init];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.preferredMaxLayoutWidth = 304.0f;
    
    title.text              = NSLocalizedString(@"No Photos or Videos", nil);
    title.font              = [UIFont systemFontOfSize:26.0];
    title.textColor         = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    title.textAlignment     = NSTextAlignmentCenter;
    title.numberOfLines     = 5;
    
    NSString *format        = nil;
    
    if ([self isCameraDeviceAvailable])
        format = NSLocalizedString(@"You can take photos and videos using the camera, or sync photos and videos onto your %@\nusing iTunes.", nil);
    else
        format = NSLocalizedString(@"You can sync photos and videos onto your %@ using iTunes.", nil);
    
    message.text            = [NSString stringWithFormat:format, [self deviceModel]];
    message.font            = [UIFont systemFontOfSize:18.0];
    message.textColor       = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1];
    message.textAlignment   = NSTextAlignmentCenter;
    message.numberOfLines   = 5;
    
    [title sizeToFit];
    [message sizeToFit];
    
    UIView *centerView = [[UIView alloc] init];
    centerView.translatesAutoresizingMaskIntoConstraints = NO;
    [centerView addSubview:title];
    [centerView addSubview:message];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(title, message);
    
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:centerView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraint:[NSLayoutConstraint constraintWithItem:message attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [centerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]-[message]|" options:0 metrics:nil views:viewsDictionary]];
    
    UIView *view = [[UIView alloc] init];
    [view addSubview:centerView];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:centerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    return view;
}

@end




#pragma mark - CTAssetsGroupViewController

@implementation CTAssetsGroupViewController


- (id)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.preferredContentSize = kPopoverContentSize;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupButtons];
    [self localize];
    [self setupGroup];
}


#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


#pragma mark - Setup

- (void)setupViews
{
    self.tableView.rowHeight = kThumbnailLength + 12;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)setupButtons
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    
    if (picker.showsCancelButton)
    {
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(dismiss:)];
    }
}

- (void)localize
{
    self.title = NSLocalizedString(@"Photos", nil);
}

- (void)setupGroup
{
    if (!self.assetsLibrary)
        self.assetsLibrary = [self.class defaultAssetsLibrary];
    
    if (!self.groups)
        self.groups = [[NSMutableArray alloc] init];
    else
        [self.groups removeAllObjects];
    
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAssetsFilter *assetsFilter = picker.assetsFilter;
    
    ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if (group)
        {
            [group setAssetsFilter:assetsFilter];
            
            if ([picker.delegate respondsToSelector:@selector(assetsPickerController:shouldShowAssetsGroup:)])
            {
                if ([picker.delegate assetsPickerController:picker shouldShowAssetsGroup:group])
                    [self.groups addObject:group];
            }
            else
            {
                [self.groups addObject:group];
            }
        }
        else
        {
            [self reloadData];
        }
    };
    
    
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error)
    {
        [self showNotAllowed];
    };
    
    // Enumerate Camera roll first
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                      usingBlock:resultsBlock
                                    failureBlock:failureBlock];
    
    // Then all other groups
    NSUInteger type =
    ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent |
    ALAssetsGroupFaces | ALAssetsGroupPhotoStream;
    
    [self.assetsLibrary enumerateGroupsWithTypes:type
                                      usingBlock:resultsBlock
                                    failureBlock:failureBlock];
}


#pragma mark - Reload Data

- (void)reloadData
{
    if (self.groups.count > 0)
        [self.tableView reloadData];
    else
        [self showNoAssets];
}


#pragma mark - ALAssetsLibrary

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred,^
    {
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}


#pragma mark - Not allowed / No assets

- (void)showNotAllowed
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    self.title                       = nil;
    self.tableView.backgroundView    = [picker notAllowedView];
}

- (void)showNoAssets
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    self.tableView.backgroundView    = [picker noAssetsView];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    CTAssetsGroupViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[CTAssetsGroupViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [cell bind:[self.groups objectAtIndex:indexPath.row]];
    
    return cell;
}


#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kThumbnailLength + 12;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsViewController *vc = [[CTAssetsViewController alloc] init];
    vc.assetsGroup = [self.groups objectAtIndex:indexPath.row];

    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions

- (void)dismiss:(id)sender
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerControllerDidCancel:)])
        [picker.delegate assetsPickerControllerDidCancel:picker];
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end



#pragma mark - CTAssetsGroupViewCell

@implementation CTAssetsGroupViewCell


- (void)bind:(ALAssetsGroup *)assetsGroup
{
    self.assetsGroup            = assetsGroup;
    
    CGImageRef posterImage      = assetsGroup.posterImage;
    size_t height               = CGImageGetHeight(posterImage);
    float scale                 = height / kThumbnailLength;
    
    self.imageView.image        = [UIImage imageWithCGImage:posterImage scale:scale orientation:UIImageOrientationUp];
    self.textLabel.text         = [assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    self.detailTextLabel.text   = [NSString stringWithFormat:@"%ld", (long)[assetsGroup numberOfAssets]];
    self.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
}

- (NSString *)accessibilityLabel
{
    NSString *label = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    return [label stringByAppendingFormat:NSLocalizedString(@"%ld Photos", nil), (long)[self.assetsGroup numberOfAssets]];
}

@end




#pragma mark - CTAssetsViewController

#define kAssetsViewCellIdentifier           @"AssetsViewCellIdentifier"
#define kAssetsSupplementaryViewIdentifier  @"AssetsSupplementaryViewIdentifier"

@implementation CTAssetsViewController

- (id)init
{
    self.layout                         = [[UICollectionViewFlowLayout alloc] init];
    self.layout.itemSize                = kThumbnailSize;
    self.layout.footerReferenceSize     = CGSizeMake(0, 44.0);
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) &&
        (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad))
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 2.0, 0, 2.0);
        self.layout.minimumInteritemSpacing = 3.0;
        self.layout.minimumLineSpacing      = 3.0;
    }
    else
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 0, 0, 0);
        self.layout.minimumInteritemSpacing = 2.0;
        self.layout.minimumLineSpacing      = 2.0;
    }
    
    if (self = [super initWithCollectionViewLayout:self.layout])
    {
        self.collectionView.allowsMultipleSelection = YES;
        
        [self.collectionView registerClass:[CTAssetsViewCell class]
                forCellWithReuseIdentifier:kAssetsViewCellIdentifier];
        
        [self.collectionView registerClass:[CTAssetsSupplementaryView class]
                forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                       withReuseIdentifier:kAssetsSupplementaryViewIdentifier];

        self.preferredContentSize = kPopoverContentSize;
    }
    
    self.selectedAssets = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupAssets];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setSelectedAssets:nil];
    [self updateSelectedAssets];
}


#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 2.0, 0, 2.0);
        self.layout.minimumInteritemSpacing = 3.0;
        self.layout.minimumLineSpacing      = 3.0;
    }
    else
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 0, 0, 0);
        self.layout.minimumInteritemSpacing = 2.0;
        self.layout.minimumLineSpacing      = 2.0;
    }
    
    [self.collectionView setCollectionViewLayout:self.layout animated:YES];
}


#pragma mark - Setup

- (void)setupViews
{
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)setupButtons
{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(finishPickingAssets:)];
}

- (void)setupAssets
{
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    self.numberOfPhotos = 0;
    self.numberOfVideos = 0;
    
    if (!self.assets)
        self.assets = [[NSMutableArray alloc] init];
    else
        [self.assets removeAllObjects];
    
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset)
        {
            [self.assets addObject:asset];
            
            NSString *type = [asset valueForProperty:ALAssetPropertyType];
            
            if ([type isEqual:ALAssetTypePhoto])
                self.numberOfPhotos ++;
            if ([type isEqual:ALAssetTypeVideo])
                self.numberOfVideos ++;
        }
        else
        {
            [self reloadData];
        }
    };
    
    [self.assetsGroup enumerateAssetsUsingBlock:resultsBlock];
}



#pragma mark - Selected Assets

- (void)updateSelectedAssets
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;

    if (self.selectedAssets.count > 0)
        picker.selectedAssets = [NSArray arrayWithArray:self.selectedAssets];
    else
        picker.selectedAssets = nil;
}


#pragma mark - Reload Data

- (void)reloadData
{
    if (self.assets.count > 0)
    {
        [self.collectionView reloadData];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.assets.count-1 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:YES];
    }
    else
    {
        [self showNoAssets];
    }
}


#pragma mark - No assets

- (void)showNoAssets
{
    CTAssetsPickerController *picker    = (CTAssetsPickerController *)self.navigationController;
    self.collectionView.backgroundView  = [picker noAssetsView];
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kAssetsViewCellIdentifier;
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    
    CTAssetsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ALAsset *asset  = [self.assets objectAtIndex:indexPath.row];
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:shouldEnableAssetForSelection:)])
        cell.disabled = ![picker.delegate assetsPickerController:picker shouldEnableAssetForSelection:asset];
    else
        cell.disabled = NO;
    
    [cell bind:asset];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *viewIdentifiert = kAssetsSupplementaryViewIdentifier;
    
    CTAssetsSupplementaryView *view =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:viewIdentifiert forIndexPath:indexPath];

    if (self.assets.count > 0)
        [view setNumberOfPhotos:self.numberOfPhotos numberOfVideos:self.numberOfVideos];
    
    return view;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:shouldSelectAsset:)])
        return [picker.delegate assetsPickerController:picker shouldSelectAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    [self.selectedAssets addObject:asset];
    [self updateSelectedAssets];
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didSelectAsset:)])
        [picker.delegate assetsPickerController:picker didSelectAsset:asset];
    
    [self setTitleWithSelectedIndexPaths:collectionView.indexPathsForSelectedItems];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:shouldDeselectAsset:)])
        return [picker.delegate assetsPickerController:picker shouldDeselectAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    [self.selectedAssets removeObject:asset];
    [self updateSelectedAssets];
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didDeselectAsset:)])
        [picker.delegate assetsPickerController:picker didDeselectAsset:asset];
    
    [self setTitleWithSelectedIndexPaths:collectionView.indexPathsForSelectedItems];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];

    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:shouldHighlightAsset:)])
        return [picker.delegate assetsPickerController:picker shouldHighlightAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didHighlightAsset:)])
        [picker.delegate assetsPickerController:picker didHighlightAsset:asset];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didUnhighlightAsset:)])
        [picker.delegate assetsPickerController:picker didUnhighlightAsset:asset];
}


#pragma mark - Title

- (void)setTitleWithSelectedIndexPaths:(NSArray *)indexPaths
{
    // Reset title to group name
    if (indexPaths.count == 0)
    {
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        return;
    }
    
    BOOL photosSelected = NO;
    BOOL videoSelected  = NO;
    
    for (NSIndexPath *indexPath in indexPaths)
    {
        ALAsset *asset = [self.assets objectAtIndex:indexPath.item];
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto])
            photosSelected  = YES;
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo])
            videoSelected   = YES;
        
        if (photosSelected && videoSelected)
            break;
    }
    
    NSString *format;
    
    if (photosSelected && videoSelected)
        format = NSLocalizedString(@"%ld Items Selected", nil);
    
    else if (photosSelected)
        format = (indexPaths.count > 1) ? NSLocalizedString(@"%ld Photos Selected", nil) : NSLocalizedString(@"%ld Photo Selected", nil);
    
    else if (videoSelected)
        format = (indexPaths.count > 1) ? NSLocalizedString(@"%ld Videos Selected", nil) : NSLocalizedString(@"%ld Video Selected", nil);
    
    self.title = [NSString stringWithFormat:format, (long)indexPaths.count];
}


#pragma mark - Actions

- (void)finishPickingAssets:(id)sender
{
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems)
    {
        [assets addObject:[self.assets objectAtIndex:indexPath.item]];
    }
    
    CTAssetsPickerController *picker = (CTAssetsPickerController *)self.navigationController;
    
    if ([picker.delegate respondsToSelector:@selector(assetsPickerController:didFinishPickingAssets:)])
        [picker.delegate assetsPickerController:picker didFinishPickingAssets:assets];
}

@end



#pragma mark - CTAssetsViewCell

@implementation CTAssetsViewCell

static UIFont *titleFont = nil;

static CGFloat titleHeight;
static UIImage *videoIcon;
static UIColor *titleColor;
static UIImage *checkedIcon;
static UIColor *selectedColor;
static UIColor *disabledColor;

+ (void)initialize
{
    titleFont       = [UIFont systemFontOfSize:12];
    titleHeight     = 20.0f;
    videoIcon       = [UIImage imageNamed:@"CTAssetsPickerVideo"];
    titleColor      = [UIColor whiteColor];
    checkedIcon     = [UIImage imageNamed:@"CTAssetsPickerChecked"];
    selectedColor   = [UIColor colorWithWhite:1 alpha:0.3];
    disabledColor   = [UIColor colorWithWhite:1 alpha:0.9];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque                     = YES;
        self.isAccessibilityElement     = YES;
        self.accessibilityTraits        = UIAccessibilityTraitImage;
    }
    
    return self;
}

- (void)bind:(ALAsset *)asset
{
    self.asset  = asset;
    self.image  = [UIImage imageWithCGImage:asset.thumbnail];
    self.type   = [asset valueForProperty:ALAssetPropertyType];
    
    if ([self.type isEqual:ALAssetTypeVideo])
    {
        self.title = [NSDate timeDescriptionOfTimeInterval:[[asset valueForProperty:ALAssetPropertyDuration] doubleValue]];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}


// Draw everything to improve scrolling responsiveness

- (void)drawRect:(CGRect)rect
{
    // Image
    [self.image drawInRect:CGRectMake(0, 0, kThumbnailLength, kThumbnailLength)];
    
    // Video title
    if ([self.type isEqual:ALAssetTypeVideo])
    {
        // Create a gradient from transparent to black
        CGFloat colors [] = {
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.8,
            0.0, 0.0, 0.0, 1.0
        };
        
        CGFloat locations [] = {0.0, 0.75, 1.0};
        
        CGColorSpaceRef baseSpace   = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient      = CGGradientCreateWithColorComponents(baseSpace, colors, locations, 2);
        
        CGContextRef context    = UIGraphicsGetCurrentContext();
        
        CGFloat height          = rect.size.height;
        CGPoint startPoint      = CGPointMake(CGRectGetMidX(rect), height - titleHeight);
        CGPoint endPoint        = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
        
        CGSize titleSize        = [self.title sizeWithAttributes:@{NSFontAttributeName : titleFont}];
        CGRect titleRect        = CGRectMake(rect.size.width - titleSize.width - 2, startPoint.y + (titleHeight - 12) / 2, titleSize.width, titleHeight);
        
        NSMutableParagraphStyle *titleStyle = [[NSMutableParagraphStyle alloc] init];
        titleStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        
        [self.title drawInRect:titleRect
                withAttributes:@{NSFontAttributeName : titleFont,
                                 NSForegroundColorAttributeName : titleColor,
                                 NSParagraphStyleAttributeName : titleStyle}];
        
        [videoIcon drawAtPoint:CGPointMake(2, startPoint.y + (titleHeight - videoIcon.size.height) / 2)];
    }
    
    if (self.disabled)
    {
        CGContextRef context    = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, disabledColor.CGColor);
		CGContextFillRect(context, rect);
    }
    
    else if (self.selected)
    {
        CGContextRef context    = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, selectedColor.CGColor);
		CGContextFillRect(context, rect);
        
        [checkedIcon drawAtPoint:CGPointMake(CGRectGetMaxX(rect) - checkedIcon.size.width, CGRectGetMinY(rect))];
    }
}


- (NSString *)accessibilityLabel
{
    ALAssetRepresentation *representation = self.asset.defaultRepresentation;
    
    NSMutableArray *labels          = [[NSMutableArray alloc] init];
    NSString *type                  = [self.asset valueForProperty:ALAssetPropertyType];
    NSDate *date                    = [self.asset valueForProperty:ALAssetPropertyDate];
    CGSize dimension                = representation.dimensions;
    
    
    // Type
    if ([type isEqual:ALAssetTypeVideo])
        [labels addObject:NSLocalizedString(@"Video", nil)];
    else
        [labels addObject:NSLocalizedString(@"Photo", nil)];
    
    // Orientation
    if (dimension.height >= dimension.width)
        [labels addObject:NSLocalizedString(@"Portrait", nil)];
    else
        [labels addObject:NSLocalizedString(@"Landscape", nil)];
    
    // Date
    NSDateFormatter *df             = [[NSDateFormatter alloc] init];
    df.locale                       = [NSLocale currentLocale];
    df.dateStyle                    = NSDateFormatterMediumStyle;
    df.timeStyle                    = NSDateFormatterShortStyle;
    df.doesRelativeDateFormatting   = YES;
    
    [labels addObject:[df stringFromDate:date]];
    
    return [labels componentsJoinedByString:@", "];
}


@end


#pragma mark - CTAssetsSupplementaryView

@implementation CTAssetsSupplementaryView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _sectionLabel               = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, 8.0, 8.0)];
        _sectionLabel.font          = [UIFont systemFontOfSize:18.0];
        _sectionLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_sectionLabel];
        
        self.translatesAutoresizingMaskIntoConstraints          = NO;
        _sectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_sectionLabel
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                          constant:0.0f]];
    }
    
    return self;
}

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos numberOfVideos:(NSInteger)numberOfVideos
{
    NSString *title;
    
    if (numberOfVideos == 0)
        title = [NSString stringWithFormat:NSLocalizedString(@"%ld Photos", nil), (long)numberOfPhotos];
    else if (numberOfPhotos == 0)
        title = [NSString stringWithFormat:NSLocalizedString(@"%ld Videos", nil), (long)numberOfVideos];
    else
        title = [NSString stringWithFormat:NSLocalizedString(@"%ld Photos, %ld Videos", nil), (long)numberOfPhotos, (long)numberOfVideos];
    
    self.sectionLabel.text = title;
}

@end
