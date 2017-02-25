#include "ASCreatorsListController.h"
#import "ASRootListController.h"
#import "asphaleiaTVC.h"

@implementation ASCreatorsListController

- (NSArray *)specifiers {
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Creators";
}
- (id)init {
    self = [super init];
    if (self) {
        if([[NSFileManager defaultManager]fileExistsAtPath:kPreferencesPath]){
           CPPrefs = [[NSMutableDictionary alloc]initWithContentsOfFile:kPreferencesPath];
        } else {
            CPPrefs = [[NSMutableDictionary alloc]init];
        }
    }
    return self;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}
- (id)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *handleString;
    switch (indexPath.section) {
        case 0:
            handleString = @"Sentry_NC";
            break;
        case 1:
            handleString = @"evilgoldfish01";
            break;
        case 2:
            handleString = @"CallumRyan314";
            break;
        case 3:
            handleString = @"ShadeZepheri";
            break;
        case 4:
            handleString = @"A3tweaks";
            break;
        default:
            return;
    }
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *tweetbot = [NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:handleString]];
    if ([app canOpenURL:tweetbot]) {
      [app openURL:tweetbot];
    } else {
        NSURL *twitterapp = [NSURL URLWithString:[@"twitter:///user?screen_name=" stringByAppendingString:handleString]];
        if ([app canOpenURL:twitterapp]) {
          [app openURL:twitterapp];
        } else {
            NSURL *twitterweb = [NSURL URLWithString:[@"http://twitter.com/" stringByAppendingString:handleString]];
            [app openURL:twitterweb];
        }
    }
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSString *reuseIdentifier = @"Profile";
    asphaleiaTVC *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (cell == nil) {
        cell = [[asphaleiaTVC alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    switch (section) {
        case 0:
            [cell loadImage:@"Sentry" nameText:@"Sentry" handleText:@"(@Sentry_NC)" infoText:@"Visual Interaction Designer,\rAuxo, Apex, AltKB, Aplo,\rFounder of A³tweaks."];
            break;
        case 1:
            [cell loadImage:@"Evan" nameText:@"Evan" handleText:@"(@evilgoldfish01)" infoText:@"iOS and OSX Developer,\nLockGlyph, NoPlayerBlur,\nStudent."];
            break;
        case 2:
            [cell loadImage:@"Callum" nameText:@"Callum" handleText:@"(@CallumRyan314)" infoText:@"iOS Developer,\nSMS Stats,\nOriginal Asphaleia developer."];
            break;
        case 3:
            [cell loadImage:@"Shade" nameText:@"Shade" handleText:@"(@ShadeZepheri)" infoText:@"iOS Developer,\nZypen, Domum,\nStudent."];
            break;
        case 4:
            [cell loadImage:nil nameText:nil handleText:nil infoText:nil];
            cell.textLabel.text = @"Follow A3tweaks";
            cell.imageView.image = [UIImage imageNamed:@"GroupLogo.png" inBundle:[[NSBundle alloc] initWithPath:kBundlePath] compatibleWithTraitCollection:nil];
            break;
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (id)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 4) {
      return 106.0f;
    } else {
      return 44.0f;
    }
}

- (CGFloat)tableView:(id)arg1 estimatedHeightForRowAtIndexPath:(id)arg2 {
    return 44.0f;
}

- (id)_tableView:(id)arg1 viewForCustomInSection:(long long)arg2 isHeader:(bool)arg3 {
    return nil;
}

- (CGFloat)_tableView:(id)arg1 heightForCustomInSection:(long long)arg2 isHeader:(bool)arg3 {
    return 0.0f;
}

@end
