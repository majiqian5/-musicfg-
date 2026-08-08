ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = musicfg
musicfg_FILES = MFGRootListController.m
musicfg_INSTALL_PATH = /Library/PreferenceBundles
musicfg_FRAMEWORKS = UIKit
musicfg_PRIVATE_FRAMEWORKS = Preferences
musicfg_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/musicfg.plist$(ECHO_END)
