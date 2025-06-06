--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.MCU_Interrupts;
with RTG.Runtime;

package RTG.System_BB_MCU_Vectors is

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts : RTG.MCU_Interrupts.Interrupt_Information_Vectors.Vector);

end RTG.System_BB_MCU_Vectors;
