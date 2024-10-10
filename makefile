APP_NAME := DEMO

TOOLCHAIN := arm-none-eabi
CC := $(TOOLCHAIN)-gcc

# CMSIS
CMSIS_PATH := ./../../xdk-asf-3.52.0/sam0/utils/cmsis/samc21
LD_PATH    := ./../../xdk-asf-3.52.0/sam0/utils/linker_scripts/samc21/gcc

# third-party arm_math...
THIRDPARTY_PATH := ./../../xdk-asf-3.52.0/thirdparty/CMSIS

# apps source folder
SRC_PATH := ./src
OBJ_PATH := ./obj

# apps src
src := $(shell find ./src -name *.c)
obj += $(patsubst $(SRC_PATH)/%.c, $(OBJ_PATH)/%.o, $(src))

#ARM CORTEX-M0+ CMSIS startup file
startup_src += $(wildcard $(CMSIS_PATH)/source/gcc/*.c)
startup_obj += $(patsubst $(CMSIS_PATH)/%.c, $(OBJ_PATH)/cmsis/%.o, $(startup_src))

# ARM DSP, Math support
# arm_dsp_src += $(wildcard $(THIRDPARTY_PATH)/DSP_Lib/Source/**/*.c)
# arm_dsp_obj +=

# FreeRTOS support
# freertos_src +=
# freertos_obj +=

linker_script := $(LD_PATH)/samc21j18a_flash.ld
specs := --specs=nosys.specs
mcu := -mcpu=cortex-m0plus -mfloat-abi=soft -mthumb

CFLAGS += $(mcu) $(specs)
CFLAGS += -DDONT_USE_CMSIS_INIT -D__SAMC21J18A__
CFLAGS += -I$(CMSIS_PATH)/include -I$(CMSIS_PATH)/include/instance -I$(CMSIS_PATH)/include/component #CMSIS INSTANCE
CFLAGS += -I$(THIRDPARTY_PATH)/Include
CFLAGS += -Wall -Werror-implicit-function-declaration -g -gdwarf-4 -O0
CFLAGS += -c -o

LDFLAGS += $(mcu) $(specs)
LDFLAGS += -DDONT_USE_CMSIS_INIT -D__SAMC21J18A__
LDFLAGS += -L$(THIRDPARTY_PATH)/Include
LDFLAGS += -L$(THIRDPARTY_PATH)/Lib/GCC
LDFLAGS += -lc -lm -lg -lgcc -lrdimon -lnosys
LDFLAGS += -Wl,--gc-sections -Wl,-print-memory-usage -Wl,-Map=./$(APP_NAME).map
LDFLAGS += -g -gdwarf-4 -O0

# ARM DSP and math
#LDFLAGS += -L$(THIRDPARTY_PATH)/Lib

# LINKER DESCIPRTOR
LDFLAGS += -T$(linker_script)

.PHONY : all

objs := $(startup_obj) $(obj)
all: check_obj_path $(APP_NAME).elf

clean:
	rm ./obj/* -rf
	rm ./$(APP_NAME).elf
	rm ./$(APP_NAME).map

path := $(dir $(objs))
check_obj_path:
	@echo check $(OBJ_PATH) files path ... 
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
