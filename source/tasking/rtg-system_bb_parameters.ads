--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings;

with RTG.Runtime;

package RTG.System_BB_Parameters is

   type System_BB_Parameters_Descriptor is record
      Clock_Frequency           : VSS.Strings.Virtual_String;
      ARM_Num_IRQ_Priority_Bits : VSS.Strings.Virtual_String;
      ARM_Has_FPU               : Boolean;
   end record;

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Descriptor : System_BB_Parameters_Descriptor);

end RTG.System_BB_Parameters;
