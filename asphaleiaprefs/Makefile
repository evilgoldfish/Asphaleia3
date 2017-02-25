ARCHS = armv7 arm64
TARGET = iphone:9.2
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AsphaleiaPrefs
AsphaleiaPrefs_FILES = ASRootListController.mm AsphaleiaTitleCell.m ASCreatorsListController.mm ASPasscodeOptionsListController.mm ASAdvancedOptionsListController.mm ASControlPanelListController.mm ASAdvancedSecurityListController.mm ASSecuredItemsListController.mm ASSecuredFoldersListController.mm ASSecuredAppsListController.mm ASSecuredSettingsListController.mm ASSecuredSwitchesListController.mm ASFingerprintsListController.mm asphaleiaTVC.m modalPinVC.mm TouchIDInfo.mm
AsphaleiaPrefs_INSTALL_PATH = /Library/PreferenceBundles
AsphaleiaPrefs_FRAMEWORKS = UIKit CoreGraphics AudioToolbox QuartzCore Social MessageUI SystemConfiguration LocalAuthentication
AsphaleiaPrefs_PRIVATE_FRAMEWORKS = Preferences
AsphaleiaPrefs_LDFLAGS = -L"../.theos/obj/debug" -lapplist -lmobilegestalt -lflipswitch -lrocketbootstrap -lasphaleiaui

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AsphaleiaPrefs.plist$(ECHO_END)
