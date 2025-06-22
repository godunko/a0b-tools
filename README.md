# A0B Tools: Runtime Generator

This crate provides utility to construct custom GNAT runtime for bare board applications. 
It supports construction of three well known runtime profiles: `light`, `light-tasking` and `embedded` with necessary customization for particular project.
Startup code and linker script should be provided by the application for now.

## Ideas

* Separate GNAT runtime from startup code and hardware configuration
* Fine tuning of GNAT runtime (set of packages, stack size, etc.) by single configuration file
* Support different tasking profiles, including GNAT's and custom RTOSes

## Runtime descriptor file

Typical content of the `runtime.json`

```json
{
  "tasking": "light",
  "dt:&cpu0:compatible": "arm,cortex-m4f",
  "dt:&cpu0:clock-frequency": "150_000_000",
  "dt:&nvic:arm,num-irq-priority-bits": "4",

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

Supported parameters are:
* `tasking`: tasking profile for runtime library, possible values are `no`, `light`, `embedded`
* `dt:&cpu0:compatible`: CPU architecture, only supported value is `arm,cortex-m4f`
* `dt:&cpu0:clock-frequency`: CPU frequency
* `dt:&nvic:arm,num-irq-priority-bits` number of bits of priority supported by MCU's NVIC
* `scenarios`: scenario variables to be used to construct GNAT runtime

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
