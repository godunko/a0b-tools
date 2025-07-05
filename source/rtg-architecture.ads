--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.GNAT_RTS_Sources;
with RTG.Startup;
with RTG.System;
with RTG.System_BB_Parameters;
with RTG.Tasking;

package RTG.Architecture is

   procedure Process
     (Tasking              : RTG.Tasking.Tasking_Descriptor;
      Startup              : in out RTG.Startup.Startup_Descriptor;
      Scenarios            : in out RTG.GNAT_RTS_Sources.Scenario_Maps.Map;
      System_Parameters    : in out RTG.System.System_Descriptor;
      System_BB_Parameters : in out
        RTG.System_BB_Parameters.System_BB_Parameters_Descriptor);

end RTG.Architecture;
