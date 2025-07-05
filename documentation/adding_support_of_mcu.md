# Adding support of MCU

Table of Content

 * [Alire manifest](#alire-manifest)
 * [SVD file](#svd-file)
 * [Binding information](#binding-information)
 * [System's clock configuration subprogram](#systems-clock-configuration-subprogram)

Runtime generator requires some additional information to be able to generate runtime for particular MCU
 * SVD file
 * System's Clock configuration subprogram
 * Binding information to configure system's clock configuration subprogram

An example of crate that provides such information is [`a0b_stm32f401`](https://github.com/godunko/a0b-stm32f401) crate.

## Alire manifest

Alire manifest is used to pass name of the SVD file and name of binding information files to `a0b-tools`.
`A0B_TOOLS_BINDING_STARTUP` and `A0B_TOOLS_SVD` should be set in the `alire.toml` file

```
[environment]
A0B_TOOLS_BINDING_STARTUP.set = "${CRATE_ROOT}/binding/startup/stm32f401.json"
A0B_TOOLS_SVD.set = "${CRATE_ROOT}/svd/STM32F401.svd"
```

## SVD file

SVD file need to be included into the crate. In the example crate it is located in `<crate>/svd` directory.

## Binding information

Binding information file uses JSON format and contains:
 * name of the project file to be `with`-ed by generated startup project
 * name of the compilation unit to be `with`-ed by generated startup code
 * name of the generic subprogram to be instantiated to crate system clock configuration subprogram
 * list of format parameters and their mapping to names of application's configuration parameters

```
{
  "project": "a0b_stm32f401.gpr",
  "unit": "A0B.STM32F401.Startup_Utilities",
  "subprogram": "A0B.STM32F401.Startup_Utilities.Generic_Configure_System_Clocks",
  "parameters":
  {
    "FLASH_LATENCY": "dt:&flash:latency",
    "VOS_SCALE": "dt:&pwr:vos",
    "PLL_M": "dt:&pll:div-m",
    "PLL_N": "dt:&pll:mul-n",
    "PLL_P": "dt:&pll:div-p",
    "PLL_Q": "dt:&pll:div-q",
    "AHB": "dt:&rcc:ahb-prescaler",
    "APB1": "dt:&rcc:apb1-prescaler",
    "APB2": "dt:&rcc:apb2-prescaler"
  }
}
```

It is recommeneded to select names of application's configuration parameters close to use by DeviceTree specifications in Linux/Zephyr.

## System's clock configuration subprogram

System's clock configuration subprogram should be an Ada generic subprogram, in the generated startup code values for its format parameters are taken from application's runtime configuration.

Note, some restrictions are applied to code of generic system's clock configuration subprogram:
 * package must have `No_Elaboration_Code_All` aspect: this code is executed before elaboration procedure

```
package A0B.STM32F401.Startup_Utilities
  with Preelaborate, No_Elaboration_Code_All
is

   generic
      FLASH_LATENCY : A0B.Types.Unsigned_32;
      VOS_SCALE     : A0B.Types.Unsigned_32;
      PLL_M         : A0B.Types.Unsigned_32;
      PLL_N         : A0B.Types.Unsigned_32;
      PLL_P         : A0B.Types.Unsigned_32;
      PLL_Q         : A0B.Types.Unsigned_32;
      AHB           : A0B.Types.Unsigned_32;
      APB1          : A0B.Types.Unsigned_32;
      APB2          : A0B.Types.Unsigned_32;

   procedure Generic_Configure_System_Clocks;

end A0B.STM32F401.Startup_Utilities;
```
