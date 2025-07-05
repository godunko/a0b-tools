# Getting Started

## Install Alire

See [Alire documentation](https://alire.ada.dev/docs/#getting-started) how to install Alire on your computer.

## Download `bb-runtimes`

`bb-runtimes` contains source code of the GNAT Runtime and GNAT Tasking.
There is no separate crate for it, so it need to be downloaded from the repository.

```
git clone --branch=gnat-fsf-15 https://github.com/alire-project/bb-runtimes.git bb-runtimes-15
```

## Create a new project

We will create Blink LED project like provided in the `example/weact_blackpill_stm32f401cc` directory.
It works on WeAct Blackpill STM32F401 board with 25 MHz external crystal resonator (there is version with 8 MHz external crystal resonator).

First, create new Alire crate

```
alr init --bin hello_led
cd hello_led
```

Next, add dependency from base support crate of the STM32F401 MCU used by board and crate that provides GPIO drivers

```
alr with a0b_stm32f401
alr with a0b_stm32f401_gpio
```

and dependency from `a0b_tools`:

```
alr with a0b_tools
```

Note, updated versions of some crates are not released yet, and need to be pinned to repositories:

```
alr pin a0b_armv7m --use https://github.com/godunko/a0b-armv7m.git
alr pin a0b_stm32f401 --use https://github.com/godunko/a0b-stm32f401.git
```

Now, modify `alire.toml` file to run `a0b-tools` to generate runtime and `gprbuild` to build runtime automatically:

```
[[actions]]
type = "pre-build"
command = ["a0b-runtime", "--bb-runtimes=../../../bb-runtimes-15/"]
[[actions]]
type = "pre-build"
command = ["gprbuild", "-j0", "runtime/build_runtime.gpr"]
[[actions]]
type = "pre-build"
command = ["gprbuild", "-j0", "runtime/build_tasking.gpr"]
[[actions]]
type = "pre-build"
command = ["gprbuild", "-j0", "runtime/build_startup.gpr"]
```

`a0b-armv7m` requires configuration parameter to select variant of FPU implemented by MCU, so add it to `alire.toml` too

```
[configuration.values]
a0b_armv7m.fpu_extension = "VFPv4"
```

Project file `hello_led.gpr` need to be modified to use `arm-eabi` compiler and generated custom runtime:

```
project Hello_Led is
   ...
   for Target use "arm-eabi";
   for Runtime ("Ada") use "runtime";
   ...
end Hello_Led;
```

Next, runtime description file `runtime.json` need to be created in the root directory of the application crate.

```
{
  "dt:&cpu0:compatible": "arm,cortex-m4f",
  "dt:&cpu0:clock-frequency": "84_000_000",
  "dt:&nvic:arm,num-irq-priority-bits": "4",
  "dt:/chosen/a0b,sram:reg": ["0x20000000", "DT_SIZE_K(32)"],
  "dt:/chosen/a0b,flash:reg": ["0x08000000", "DT_SIZE_K(64)"],
  "dt:&flash:latency": "2",
  "dt:&pwr:vos": "2",
  "dt:&pll:div-m": "25",
  "dt:&pll:mul-n": "336",
  "dt:&pll:div-p": "4",
  "dt:&pll:div-q": "7",
  "dt:&rcc:ahb-prescaler": "1",
  "dt:&rcc:apb1-prescaler": "2",
  "dt:&rcc:apb2-prescaler": "1",

  "runtime":
  {
    "common_required_switches": ["-mfloat-abi=hard", "-mcpu=cortex-m4", "-mfpu=fpv4-sp-d16"],
    "linker_required_switches": ["-nostartfiles", "-nolibc"],
    "files":
    {
      "s-macres.adb": { "crate": "bb_runtimes", "path": "src/s-macres__cortexm3.adb" },
      "s-sgshca.adb": { "crate": "bb_runtimes", "path": "src/s-sgshca__cortexm.adb" }
    }
  },

  "tasking":
  {
    "kernel": "light",
    "files":
    {
      "s-bbbosu.adb": { "crate": "bb_runtimes", "path": "src/s-bbbosu__armv7m.adb" },
      "s-bbcppr.ads": { "crate": "bb_runtimes", "path": "src/s-bbcppr__old.ads" },
      "s-bbcppr.adb": { "crate": "bb_runtimes", "path": "src/s-bbcppr__armv7m.adb" },
      "s-bbcpsp.ads": { "crate": "bb_runtimes", "path": "src/s-bbcpsp__arm.ads" },
      "s-bcpcst.ads": { "crate": "bb_runtimes", "path": "src/s-bcpcst__armvXm.ads" },
      "s-bcpcst.adb": { "crate": "bb_runtimes", "path": "src/s-bcpcst__pendsv.adb" },
      "s-bbsumu.adb": { "crate": "bb_runtimes", "path": "src/s-bbsumu__generic.adb" }
    }
  },

  "scenarios":
  {
    "Target_Word_Size": "32",
    "Has_Compare_And_Swap": "yes",
    "Has_CHERI": "no",
    "Certifiable_Packages": "no",
    "Has_libc": "no",
    "Memory_Profile": "small",
    "Text_IO": "semihosting",

    "Timer": "timer32",

    "Add_Value_Spec": "yes",
    "Add_Value_LL_Spec": "yes",

    "Add_Math_Lib": "hardfloat_sp",
    "Add_Exponent_Int": "yes",
    "Add_Streams": "yes",
    "Add_Exponent_Float": "yes",
    "Add_Value_Int": "yes",
    "Add_IO_Exceptions": "yes",
    "Add_Value_Utils": "yes",
    "Add_Case_Util": "yes",
    "Add_Arith64": "yes",
    "Add_Exponent_LL_Int": "yes",
    "Add_Complex_Type_Support": "yes",
    "Add_Float_Util": "yes",
    "Add_Image_Char": "yes",
    "Add_Value_LL_Int": "yes"
  }
}
```

Last, modify `src/hello_led.adb` file to blink led

```
pragma Ada_2022;

with A0B.STM32F401.GPIO;
with A0B.STM32F401.GPIO.PIOC;

procedure Hello_Led is
   LED   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOC.PC13;
   Value : Boolean := False;

begin
   LED.Configure_Output;

   loop
      LED.Set (Value);

      delay 1.0;

      Value := not @;
   end loop;
end Hello_Led;
```

Now build project

```
alr build
```

Built ELF executable is available in `bin/hello_led` file. It can be flashed to board to run application.

