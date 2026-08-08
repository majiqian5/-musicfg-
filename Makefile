ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = musicfg

musicfg_FILES = Tweak.xm SpectrumView.mm AuroraRingView.mm
musicfg_CFLAGS = -fobjc-arc -fno-modules
musicfg_FRAMEWORKS = UIKit QuartzCore MediaPlayer
musicfg_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
