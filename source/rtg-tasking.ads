--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings;

with RTG.System;

package RTG.Tasking is

   type Tasking_Descriptor is record
      Kernel : VSS.Strings.Virtual_String;
      Files  : RTG.File_Descriptor_Vectors.Vector;
   end record;

   procedure Process
     (Tasking           : RTG.Tasking.Tasking_Descriptor;
      Scenarios         : in out RTG.Scenario_Maps.Map;
      System_Parameters : in out RTG.System.System_Descriptor);

   function Use_GNAT_Tasking
     (Tasking : RTG.Tasking.Tasking_Descriptor) return Boolean;

end RTG.Tasking;
