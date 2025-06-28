# A0B Tools: Runtime Generator

This crate provides utility to construct custom GNAT runtime for bare board applications. 
It supports construction of three well known runtime profiles: `light`, `light-tasking` and `embedded` with necessary customization for particular project.
Optionally, it generates simple startup code and linker script.

## Ideas

* Separate GNAT runtime from startup code and hardware configuration
* Fine tuning of GNAT runtime (set of packages, stack size, etc.) by single configuration file
* Support different tasking profiles, including GNAT's and custom RTOSes

## Run runtime generator

`a0b-runtime --bb-runtimes=<path> --svd=<path>`

* `--bb-runtimes` path to `bb-runtimes` repository
* `--svd` path to SVD file of the MCU

## Use of generated runtime

To use generated runtime it is enough to set `Runtime ("Ada")` attribute to path to generated runtime.

```ada
project My_BB_Application is
   ...
   for Runtime ("Ada") use "runtime";
   ...
end My_BB_Application;
```

## Use of generated runtime and startup code/linker script

```ada
project Test extends "startup/startup.gpr" is
   ...
   for Target use "arm-eabi";
   for Runtime ("Ada") use "runtime";
   ...
end Test;

```

## Runtime descriptor file

`runtime.json` file contains configuration information to generate runtime library for the particular application.
It uses JSON5 format, which allows single line and multi line comments.
Typical content of the file:

```json5
{
  "dt:&cpu0:compatible": "arm,cortex-m4f",
  "dt:&cpu0:clock-frequency": "150_000_000",
  "dt:&nvic:arm,num-irq-priority-bits": "4",

  "runtime":
  {
    "common_required_switches": ["-mfloat-abi=hard", "-mcpu=cortex-m4"],
    "linker_required_switches": ["-nostartfiles", "-nolibc"],
    "files":
    {
      "s-macres.adb": { "crate": "bb_runtimes", "path": "src/s-macres__cortexm3.adb" },
      "s-sgshca.adb": { "crate": "bb_runtimes", "path": "src/s-sgshca__cortexm.adb" }
    }
  }

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
* `runtime`: configuration parameters of runtime
* `scenarios`: scenario variables to be used to construct GNAT runtime

#### Runtime Configuration Parameters

* `common_required_switches`: list of required switches for compiler and linker to build runtime and application.
  Architecture specific switches should be listed here.
* `linker_required_switches`: list of required switches to be used by linker.
  Usually switches to ignore default startup files and standard C library.
* `files`: additional files to be copied into runtime source directory.

#### Tasking Configuration Parameters

`tasking` section allows to define parameters of Ada tasking.  When it is omitted, regular `light` GNAT Runtime is generated.

* `kernel`: tasking kernel for runtime library, possible values are `light`, `embedded` for GNAT tasking, or custom name.
* `files`: additional files to be copied into tasking source directory.
