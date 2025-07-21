# A0B Tools: Runtime Generator

This crate provides utility to construct custom GNAT runtime for bare board application.
Generated runtime can be used with [Ada_Drivers_Library](https://github.com/AdaCore/Ada_Drivers_Library) or any others crates.

It supports construction of three well known runtime profiles: `light`, `light-tasking` and `embedded` with necessary customization for particular project.
For example, `light` runtime profile can be extended to support controlled types. 

It generates startup code and linker script too.

## Ideas

* Separate GNAT runtime from startup code and hardware configuration
* Fine tuning of GNAT runtime (set of packages, stack size, etc.) by single configuration file
* Support different tasking profiles, including GNAT's `light-tasking`/`embedded` and custom RTOSes

## Unique features

* Support of controlled types (`Ada.Finalization.Controlled`/`Ada.Finalization.Limited_Controlled`, aspect `Finalization`) for `light` runtime

## Documentation

* [Getting Started](documentation/getting_started.md)
* [Adding Support of MCU](documentation/adding_support_of_mcu.md)

## Known Limitations

* Only ARM Cortex-M3 and Cortex-M4F are supported
* Only `light` and `light-tasking` are supported

## Run runtime generator

`a0b-runtime --bb-runtimes=<path> --svd=<path>`

* `--bb-runtimes` path to `bb-runtimes` repository
* `--svd` (optional) path to SVD file of the MCU

## Use of generated runtime

To use generated runtime it is enough to set `Runtime ("Ada")` attribute to path to generated runtime.

```ada
project My_BB_Application is
   ...
   for Runtime ("Ada") use "runtime";
   ...
end My_BB_Application;
```

## Alire integration

Runtime generator is expected to be used with Alire to build application.
Board/MCU support crates provides information to generate startup code and linker script.
Following code should be added to `alire.toml` to run generator by `alr build`:

```
[[actions]]
type = "pre-build"
command = ["a0b-runtime", "--bb-runtimes=../../../bb-runtimes-15/"]
[[actions]]
type = "pre-build"
command = ["gprbuild", "-j0", "runtime/build_runtime.gpr"]
```

## Runtime descriptor file

`runtime.json` file contains configuration information to generate runtime library for the particular application.
It uses JSON5 format, which allows single line and multi line comments.
Typical content of the file:

```json5
{
  "dt:&cpu0:compatible": "arm,cortex-m4f",
  "dt:&cpu0:clock-frequency": "84_000_000",
  "dt:&nvic:arm,num-irq-priority-bits": "4",
  "dt:/chosen/a0b,sram:reg": ["0x20000000", "DT_SIZE_K(64)"],
  "dt:/chosen/a0b,flash:reg": ["0x08000000", "DT_SIZE_K(256)"],
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
    "system":
    {
      "restrictions":
      {
        "No_Finalization": true
      }
    },
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
      "s-bbbosu.adb": { "crate": "bb_runtimes", "path": "src/s-bbbosu__armv7m.adb" },  //  System.BB.Board_Support (body)
      "s-bbcppr.ads": { "crate": "bb_runtimes", "path": "src/s-bbcppr__old.ads" },     //  System.BB.CPU_Primitives (spec)
      "s-bbcppr.adb": { "crate": "bb_runtimes", "path": "src/s-bbcppr__armv7m.adb" },  //  System.BB.CPU_Primitives (body)
      "s-bbcpsp.ads": { "crate": "bb_runtimes", "path": "src/s-bbcpsp__arm.ads" },     //  System.BB.CPU_Specific (spec)
      "s-bcpcst.ads": { "crate": "bb_runtimes", "path": "src/s-bcpcst__armvXm.ads" },  //  System.BB.CPU_Primitives.Context_Switch_Trigger (spec)
      "s-bcpcst.adb": { "crate": "bb_runtimes", "path": "src/s-bcpcst__pendsv.adb" },  //  System.BB.CPU_Primitives.Context_Switch_Trigger (body)
      "s-bbsumu.adb": { "crate": "bb_runtimes", "path": "src/s-bbsumu__generic.adb" }  //  (System.BB.Board_Support).Multiprocessors
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

### General Parameter

* `dt:&cpu0:compatible`: CPU architecture, only supported value is `arm,cortex-m4f`
* `dt:&cpu0:clock-frequency`: CPU frequency
* `dt:&nvic:arm,num-irq-priority-bits` number of bits of priority supported by MCU's NVIC
* `dt:/chosen/a0b,sram:reg`: SRAM address and size (required for linker script generation)
* `dt:/chosen/a0b,flash:reg`: FLASH address and size (required for linker script generation)
* `dt:&flash:latency`: flash latency (reqired for system clock configuration)
* `dt:&pwr:vos`: voltage scaling (reqired for system clock configuration)
* `dt:&pll:div-m`: PLL `M` divider (reqired for system clock configuration)
* `dt:&pll:mul-n`: PLL `N` multiplier (reqired for system clock configuration)
* `dt:&pll:div-p`: PLL `P` divider (reqired for system clock configuration)
* `dt:&pll:div-q`: PLL `Q` divider (reqired for system clock configuration)
* `dt:&rcc:ahb-prescaler`: AHB prescaler (reqired for system clock configuration)
* `dt:&rcc:apb1-prescaler`: APB1 prescaler (reqired for system clock configuration)
* `dt:&rcc:apb2-prescaler`: APB2 prescaler (reqired for system clock configuration)
* `runtime`: configuration parameters of runtime
* `scenarios`: scenario variables to be used to construct GNAT runtime

#### Runtime Configuration Parameters

* `common_required_switches`: list of required switches for compiler and linker to build runtime and application.
  Architecture specific switches should be listed here.
* `linker_required_switches`: list of required switches to be used by linker.
  Usually switches to ignore default startup files and standard C library.
* `system`: global system configuration
  * `restrictions`: Ada restrictions to be applied for runtime and application.
    * `No_Finalization`: set to don't allow to use controlled types.
* `files`: additional files to be copied into runtime source directory.

#### Tasking Configuration Parameters

`tasking` section allows to define parameters of Ada tasking.  When it is omitted, regular `light` GNAT Runtime is generated.

* `kernel`: tasking kernel for runtime library, possible values are `light`, `embedded` for GNAT tasking, or custom name.
* `files`: additional files to be copied into tasking source directory.

#### Startup Configuration Parameters
