#

menu "Boot"

config RK_BOOT_IMG
	string "boot image"
	default "boot.img"

config RK_USE_FIT_IMG
	bool "use FIT images"

if RK_USE_FIT_IMG

config RK_BOOT_FIT_ITS
	string "its script for FIT boot image"
	default "boot.its" if RK_CHIP_FAMILY = "rv1126_rv1109"
	default "zboot.its" if RK_BOOT_IMG = "zboot.img"
	default "boot.its" if RK_BOOT_IMG = "boot.img"

endif

endmenu # Boot
