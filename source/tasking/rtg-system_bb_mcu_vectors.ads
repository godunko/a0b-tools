--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.Interrupts;
with RTG.Runtime;

package RTG.System_BB_MCU_Vectors is

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts : RTG.Interrupts.Interrupt_Information_Vectors.Vector);
   --  Generates `System.BB.MCU_Interrupts` package, which contains
   --  declarations of interrupt vector table to be used by GNAT tasking.

end RTG.System_BB_MCU_Vectors;
