ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = musicfg

musicfg_FILES = Tweak.xm SpectrumView.mm AuroraRingView.mm
musicfg_CFLAGS = -fobjc-arc -fno-modules -Wno-modules
musicfg_FRAMEWORKS = UIKit QuartzCore MediaPlayer

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
