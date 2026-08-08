ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = musicfg

musicfg_FILES = Tweak.xm SpectrumView.mm AuroraRingView.mm
musicfg_CFLAGS = -fobjc-arc
musicfg_FRAMEWORKS = UIKit QuartzCore MediaPlayer AVFoundation
musicfg_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
