--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.GNAT_RTS_Sources;
with RTG.System;

package RTG.Tasking is

   procedure Process
     (Scenarios         : in out RTG.GNAT_RTS_Sources.Scenario_Maps.Map;
      System_Parameters : in out RTG.System.System_Descriptor);

   function Use_GNAT_Tasking
     (Scenarios : RTG.GNAT_RTS_Sources.Scenario_Maps.Map) return Boolean;

end RTG.Tasking;
