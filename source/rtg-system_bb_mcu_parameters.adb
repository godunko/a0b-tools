--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with VSS.Strings.Formatters.Integers;
with VSS.Strings.Templates;

with RTG.Utilities;

package body RTG.System_BB_MCU_Parameters is

   use VSS.Strings.Formatters.Integers;
   use VSS.Strings.Templates;

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts :
        RTG.System_BB_MCU_Vectors.Interrupt_Information_Vectors.Vector)
   is
      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Tasking_Source_Directory, "s-bbmcpa.ads");
      use Output;

      Number_Of_Interrupts_Template : constant Virtual_String_Template :=
        "   Number_Of_Interrupts : constant := {};";

      Max_Interrupt : Natural := 0;

   begin

      for Interrupt of Interrupts loop
         Max_Interrupt := Integer'Max (@, Interrupt.Value);
      end loop;

      NL;
      PL ("package System.BB.MCU_Parameters");
      PL ("  with Preelaborate, No_Elaboration_Code_All");
      PL ("is");
      NL;
      PL (Number_Of_Interrupts_Template.Format (Image (Max_Interrupt)));
      NL;
      PL ("end System.BB.MCU_Parameters;");
   end Generate;

end RTG.System_BB_MCU_Parameters;
