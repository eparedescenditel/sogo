# GNUstep makefile

include ../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../Version

ADDITIONAL_LDFLAGS += -Wl,--rpath,$(SOGO_SYSLIBDIR)/sogo

###
SOGO_TOOL = sogo-tool
$(SOGO_TOOL)_INSTALL_DIR = $(SOGO_ADMIN_TOOLS)
$(SOGO_TOOL)_OBJC_FILES += \
	sogo-tool.m \
	\
	SOGoTool.m \
	SOGoToolBackup.m \
	SOGoToolCheckDoubles.m \
	SOGoToolDumpDefaults.m \
	SOGoToolExpireAutoReply.m \
	SOGoToolExpireUserSessions.m \
	SOGoToolRemove.m \
	SOGoToolRemoveDoubles.m \
	SOGoToolRenameUser.m \
	SOGoToolRestore.m \
	SOGoToolUserPreferences.m \
	SOGoToolManageEAS.m
TOOL_NAME += $(SOGO_TOOL)

###
SOGO_SLAPD_SOCKD = sogo-slapd-sockd
$(SOGO_SLAPD_SOCKD)_INSTALL_DIR = $(SOGO_ADMIN_TOOLS)
$(SOGO_SLAPD_SOCKD)_OBJC_FILES += \
	sogo-slapd-sockd.m \
	\
	SOGoSockD.m \
	SOGoSockDScanner.m \
	SOGoSockDOperation.m
TOOL_NAME += $(SOGO_SLAPD_SOCKD)

###
SOGO_EALARMS_NOTIFY = sogo-ealarms-notify
$(SOGO_EALARMS_NOTIFY)_INSTALL_DIR = $(SOGO_ADMIN_TOOLS)
$(SOGO_EALARMS_NOTIFY)_OBJC_FILES += \
	sogo-ealarms-notify.m \
	\
	SOGoEAlarmsNotifier.m
TOOL_NAME += $(SOGO_EALARMS_NOTIFY)


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
