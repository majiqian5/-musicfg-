ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = musicfg

musicfg_FILES = Tweak.xm SpectrumView.mm AuroraRingView.mm
musicfg_CFLAGS = -fobjc-arc -fno-modules -fno-objc-modules -Wno-modules -Wno-unknown-warning-option
musicfg_FRAMEWORKS = UIKit QuartzCore MediaPlayer
musicfg_LDFLAGS = -Wl,-undefined,dynamic_lookup
musicfg_CCFLAGS = -std=c++11 -stdlib=libc++

include $(THEOS_MAKE_PATH)/tweak.mk
