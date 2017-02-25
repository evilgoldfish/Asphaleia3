#include "ASPasscodeOptionsListController.h"
#import "ASRootListController.h"
#import "modalPinVC.h"
#import "TouchIDInfo.h"
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <libactivator/libactivator.h>

@implementation ASPasscodeOptionsListController

- (NSArray*)specifiers {
		if (!_specifiers) {
	      _specifiers = [[self loadSpecifiersFromPlistName:@"PasscodeOptions" target:self] retain];
	  }
		
	  dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	  Class la = objc_getClass("LAActivator");
	  if (!la) {
	      [(PSSpecifier *)_specifiers[10] setProperty:@"Activator is required to use this feature." forKey:@"footerText"];
	      [(PSSpecifier *)_specifiers[11] setProperty:[NSNumber numberWithBool:NO] forKey:@"enabled"];
	  }

		if (!isTouchIDDevice()) {
			NSMutableArray *mutableSpecifiers = [_specifiers mutableCopy];
      for (PSSpecifier *specifier in [_specifiers copy]) {
          if ([[specifier identifier] isEqualToString:@"vibrateSwitchCell"] || [[specifier identifier] isEqualToString:@"touchIDSwitchCell"] || [[specifier identifier] isEqualToString:@"touchIDGroupCell"])
              [mutableSpecifiers removeObject:specifier];
      }
			_specifiers = [mutableSpecifiers copy];
  }

	  return _specifiers;
	}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"Reset All Settings"]) {
        cell.textLabel.textColor = [UIColor redColor];
    }
    return cell;
}

- (void)changePasscode {
    if ([(NSString *)[[[NSDictionary alloc]initWithContentsOfFile:kPreferencesPath] objectForKey:@"passcode"] length] == 0) {
        [(UIViewController *)[[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder] presentViewController:[[modalPinVC alloc] initToSetPasscode:self] animated:YES completion:NULL];
    } else {
        [(UIViewController *)[[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder] presentViewController:[[modalPinVC alloc] initWithDelegate:self] animated:YES completion:NULL];
    }
}

- (void)resetAllSettings {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you sure you want to reset all settings?\nYou can't undo this, and you will have to reconfigure Asphaleia yourself."
		                               message:@"This is an alert."
		                               preferredStyle:UIAlertControllerStyleActionSheet];

		UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
		   handler:^(UIAlertAction * action) {
				 NSError *error;
         NSFileManager *fileMgr = [NSFileManager defaultManager];
         if ([fileMgr removeItemAtPath:kPreferencesPath error:&error] == YES) {}
         CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
		}];

		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
		   handler:^(UIAlertAction * action) {
				 [self dismissViewControllerAnimated:YES completion:nil];
		}];

		[alert addAction:defaultAction];
		[alert addAction:cancelAction];
		[self presentViewController:alert animated:YES completion:nil];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PreferencesPath];
    if (!settings[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return settings[specifier.properties[@"key"]];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PreferencesPath]];
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:PreferencesPath atomically:YES];
    CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);

    if ([specifier.properties[@"key"] isEqualToString:@"simplePasscode"] && ![value boolValue] && isTouchIDDevice()) {
        PSSpecifier *touchIDSpecifier;
        for (PSSpecifier *forSpecifier in [[self specifiers] copy]) {
            if ([[forSpecifier identifier] isEqualToString:@"touchIDSwitchCell"])
                touchIDSpecifier = forSpecifier;
        }
        [self setPreferenceValue:[NSNumber numberWithBool:NO] specifier:touchIDSpecifier];
        [[self table] reloadData];
    } else if ([specifier.properties[@"key"] isEqualToString:@"touchID"] && [value boolValue] && isTouchIDDevice()) {
        PSSpecifier *passcodeSpecifier;
        for (PSSpecifier *forSpecifier in [[self specifiers] copy]) {
            if ([[forSpecifier identifier] isEqualToString:@"passcodeSwitchCell"])
                passcodeSpecifier = forSpecifier;
        }
        [self setPreferenceValue:[NSNumber numberWithBool:YES] specifier:passcodeSpecifier];
        [[self table] reloadData];
    }
}

@end
