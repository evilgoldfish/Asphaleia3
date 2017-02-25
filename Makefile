ARCHS = armv7 arm64
TARGET = iphone:9.2

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libasphaleiaui
libasphaleiaui_FILES = ASCommon.mm NSTimer+Blocks.m ASPreferences.mm
libasphaleiaui_FRAMEWORKS = UIKit CoreGraphics Accelerate QuartzCore SystemConfiguration AudioToolbox CoreImage LocalAuthentication Security
libasphaleiaui_INSTALL_PATH = /usr/lib
libasphaleiaui_LDFLAGS = -lrocketbootstrap
libasphaleiaui_CFLAGS = -fobjc-arc -O2 -Wno-deprecated-declarations

TWEAK_NAME = Asphaleia
Asphaleia_FILES = Tweak.xm ASXPCHandler.mm ASTouchIDController.mm ASAuthenticationController.mm ASAuthenticationAlert.xm ASAlert.xm ASControlPanel.mm ASPasscodeHandler.mm ASTouchWindow.m ASActivatorListener.mm
Asphaleia_FRAMEWORKS = UIKit CoreGraphics Accelerate QuartzCore SystemConfiguration AudioToolbox CoreImage
Asphaleia_PRIVATE_FRAMEWORKS = AppSupport
Asphaleia_LDFLAGS = -L$(THEOS_OBJ_DIR)
Asphaleia_LIBRARIES = asphaleiaui rocketbootstrap
Asphaleia_CFLAGS = -fobjc-arc -O2 -Wno-deprecated-declarations

BUNDLE_NAME = AsphaleiaAssets
AsphaleiaAssets_INSTALL_PATH = /Library/Application Support/Asphaleia

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS)/makefiles/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += asphaleiaprefs
SUBPROJECTS += asphaleiaphotosprotection
SUBPROJECTS += asphaleiaflipswitch
SUBPROJECTS += asphaleiasettingsprotection
include $(THEOS_MAKE_PATH)/aggregate.mk
