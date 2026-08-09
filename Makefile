ARCHS = arm64e
TARGET = iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = musicfg

musicfg_FILES = Tweak.x SpectrumView.m AuroraRingView.m
musicfg_CFLAGS = -fobjc-arc
musicfg_FRAMEWORKS = UIKit QuartzCore MediaPlayer

include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	mkdir -p $(THEOS_STAGING_DIR)/var/jb/Library
	@if [ -d "$(THEOS_STAGING_DIR)/Library" ]; then \
		cp -a $(THEOS_STAGING_DIR)/Library/. $(THEOS_STAGING_DIR)/var/jb/Library/; \
		rm -rf $(THEOS_STAGING_DIR)/Library; \
	fi
