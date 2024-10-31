APP_NAME := DEMO

TOOLCHAIN := arm-none-eabi
CC := $(TOOLCHAIN)-gcc

# CMSIS
CMSIS_PATH := ./../../xdk-asf-3.52.0/sam0/utils/cmsis/samc21
LD_PATH    := ./../../xdk-asf-3.52.0/sam0/utils/linker_scripts/samc21/gcc

# third-party ARM_MATH support
THIRDPARTY_PATH := ./../../xdk-asf-3.52.0/thirdparty/CMSIS

# apps source folder
SRC_PATH := ./src
OBJ_PATH := ./obj
LIB_PATH := ./../../libs

# apps libs foldes
libs += samc21_d21_nvm
# libs += LIB_NAME_HERE
# add lib folder name here 
LIB_INC := $(foreach lib,$(libs),-I$(LIB_PATH)/$(lib))

#ARM CORTEX-M0+ CMSIS startup file
startup_src += $(wildcard $(CMSIS_PATH)/source/gcc/*.c)
startup_obj += $(patsubst $(CMSIS_PATH)/%.c, $(OBJ_PATH)/cmsis/%.o, $(startup_src))

# apps src
src := $(shell find $(SRC_PATH) -name *.c)
obj += $(patsubst $(SRC_PATH)/%.c, $(OBJ_PATH)/%.o, $(src))

# apps libs
libs_src += $(foreach \
	lib_name, \
	$(libs), \
	$(shell find $(LIB_PATH)/$(lib_name) -name *.c) \
)
libs_obj += $(patsubst $(LIB_PATH)/%.c, $(OBJ_PATH)/libs/%.o, $(libs_src))

# ARM DSP, Math support
# arm_dsp_src += $(wildcard $(THIRDPARTY_PATH)/DSP_Lib/Source/**/*.c)
# arm_dsp_obj +=

# FreeRTOS support
# freertos_src +=
# freertos_obj +=

linker_script := $(LD_PATH)/samc21j18a_flash.ld
specs := --specs=nosys.specs
mcu := -mcpu=cortex-m0plus -mfloat-abi=soft -mthumb -std=gnu11

CFLAGS += $(mcu) $(specs)
CFLAGS += -DDONT_USE_CMSIS_INIT -D__SAMC21J18A__ -D_NVM_SAMC21_
# CMSIS INSTANCE
CFLAGS += -I$(CMSIS_PATH)/include -I$(CMSIS_PATH)/include/instance -I$(CMSIS_PATH)/include/component

# LIBS
CFLAGS += $(LIB_INC)

# Thirdparty
CFLAGS += -I$(THIRDPARTY_PATH)/Include

# apps
CFLAGS += -I./inc

CFLAGS += -Wall -Werror=implicit-function-declaration -g -gdwarf-4 -O0
CFLAGS += -c -o 

LDFLAGS += $(mcu) $(specs)
LDFLAGS += -DDONT_USE_CMSIS_INIT -D__SAMC21J18A__
LDFLAGS += -L$(THIRDPARTY_PATH)/Include
LDFLAGS += -L$(THIRDPARTY_PATH)/Lib/GCC
LDFLAGS += -lc -lm -lg -lgcc -lrdimon -lnosys 
LDFLAGS += -Wl,--gc-sections -Wl,--print-memory-usage -Wl,--no-warn-rwx-segments -Wl,--cref -Wl,-Map=./$(APP_NAME).map
LDFLAGS += -g -gdwarf-4 -O0

# ARM DSP and math
#LDFLAGS += -L$(THIRDPARTY_PATH)/Lib

# LINKER DESCIPRTOR
LDFLAGS += -T$(linker_script)

.PHONY : all

objs := $(startup_obj) $(obj) $(libs_obj)
all: dump_info check_obj_path $(APP_NAME).elf
	@echo done!

clean:
	rm ./obj/* -rf
	rm ./$(APP_NAME).elf
	rm ./$(APP_NAME).map

dump_info:
	@echo "----------------------------------------"
	@echo "----      SAMC21 SDK MAKEFILE       ----"
	@echo "----------------------------------------"

path := $(dir $(objs))
check_obj_path:
	@echo check .obj files path ... 
	@mkdir -p $(path)

# ELF
$(APP_NAME).elf : $(objs)
	@$(CC) $(objs) $(LDFLAGS) -o ./$@

# USER APPS .o RULES
$(OBJ_PATH)/%.o : $(SRC_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# CMSIS STARTUP .o RULES
$(OBJ_PATH)/cmsis/%.o : $(CMSIS_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# LIBS .o RULES
$(OBJ_PATH)/libs/%.o : $(LIB_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@