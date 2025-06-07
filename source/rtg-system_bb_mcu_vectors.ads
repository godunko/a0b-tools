--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.MCU_Interrupts;
with RTG.Runtime;

package RTG.System_BB_MCU_Vectors is

   procedure Generate
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : RTG.MCU_Interrupts.Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean;
      GNAT_Tasking : Boolean);
   --  Generates `System.BB.MCU_Interrupts` package, which contains
   --  declarations of interrupt vector table(s).
   --
   --  @param Startup       Generate startup vector table (ARMv7)
   --  @param Static        Extend startup vector table by MCU's interrupts
   --  @param GNAT_Tasking  Generate vector table for GNAT tasking

end RTG.System_BB_MCU_Vectors;
