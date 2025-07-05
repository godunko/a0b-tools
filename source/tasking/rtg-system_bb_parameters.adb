--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with RTG.Utilities;

package body RTG.System_BB_Parameters is

   use VSS.Strings.Formatters.Strings;
   use VSS.Strings.Templates;

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Descriptor : System_BB_Parameters_Descriptor)
   is
      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Tasking_Source_Directory, "s-bbpara.ads");
      use Output;

      Clock_Frequency_Template    : constant Virtual_String_Template :=
        "   Clock_Frequency : constant := {};";
      NVIC_Priority_Bits_Template : constant Virtual_String_Template :=
        "   NVIC_Priority_Bits : constant Cortex_Priority_Bits_Width := {};";
      Has_FPU_Template            : constant Virtual_String_Template :=
        "   Has_FPU           : constant Boolean := {};";

   begin
      --  XXX It might be ARM Cortex-M specific info

      PL ("with System.BB.MCU_Parameters;");
      NL;
      PL ("package System.BB.Parameters");
      PL ("  with Preelaborate, No_Elaboration_Code_All");
      PL ("is");
      NL;
      PL
        (Clock_Frequency_Template.Format (Image (Descriptor.Clock_Frequency)));
      PL ("   Ticks_Per_Second : constant := Clock_Frequency;");
      NL;
      PL
        (Has_FPU_Template.Format
           (Image
              (VSS.Strings.Virtual_String'
                 (if Descriptor.ARM_Has_FPU then "True" else "False"))));
      PL ("   Has_VTOR          : constant Boolean := True;");
      PL ("   Has_OS_Extensions : constant Boolean := True;");
      PL ("   Is_ARMv6m         : constant Boolean := False;");
      NL;
      PL ("   subtype Cortex_Priority_Bits_Width is Integer range 1 .. 8;");
      PL
        (NVIC_Priority_Bits_Template.Format
           (Image (Descriptor.ARM_Num_IRQ_Priority_Bits)));
      NL;
      PL ("   subtype Interrupt_Range is Integer");
      PL ("     range -1 .. MCU_Parameters.Number_Of_Interrupts;");
      NL;
      PL ("   Interrupt_Stack_Size : constant := 2 * 1024;");
      PL ("   Trap_Vectors : constant := 17;");
      PL ("   Context_Buffer_Capacity : constant := 10;");
      PL ("   Max_Number_Of_CPUs : constant := 1;");
      PL ("   Multiprocessor : constant Boolean := False;");
      NL;
      PL ("end System.BB.Parameters;");
   end Generate;

end RTG.System_BB_Parameters;
