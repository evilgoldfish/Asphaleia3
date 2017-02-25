ARCHS = armv7 arm64
TARGET = iphone:9.2

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AsphaleiaFlipswitch
AsphaleiaFlipswitch_FILES = Switch.xm
AsphaleiaFlipswitch_FRAMEWORKS = UIKit
AsphaleiaFlipswitch_LDFLAGS = -L"../.theos/obj/debug"
AsphaleiaFlipswitch_LIBRARIES = flipswitch asphaleiaui rocketbootstrap
AsphaleiaFlipswitch_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)if [ -f Preferences.plist ]; then mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AsphaleiaFlipswitch; cp Preferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AsphaleiaFlipswitch/; fi$(ECHO_END)
