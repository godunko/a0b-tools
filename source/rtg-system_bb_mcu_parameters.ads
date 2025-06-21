--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.Runtime;
with RTG.System_BB_MCU_Vectors;

package RTG.System_BB_MCU_Parameters is

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts :
        RTG.System_BB_MCU_Vectors.Interrupt_Information_Vectors.Vector);

end RTG.System_BB_MCU_Parameters;
