ARCHS = armv7 arm64
TARGET = iphone:9.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AsphaleiaPhotosProtection
AsphaleiaPhotosProtection_FILES = Tweak.xm
AsphaleiaPhotosProtection_FRAMEWORKS = UIKit
AsphaleiaPhotosProtection_PRIVATE_FRAMEWORKS = AppSupport
AsphaleiaPhotosProtection_CFLAGS = -fobjc-arc -O2 -Wno-deprecated-declarations
AsphaleiaPhotosProtection_LDFLAGS = -L"../.theos/obj/debug"
AsphaleiaPhotosProtection_LIBRARIES = asphaleiaui rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk
