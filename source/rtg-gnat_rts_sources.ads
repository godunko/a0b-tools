--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

with RTG.Runtime;
limited with RTG.Tasking;

package RTG.GNAT_RTS_Sources is

   procedure Copy
     (Runtime     : RTG.Runtime.Runtime_Descriptor'Class;
      Tasking     : RTG.Tasking.Tasking_Descriptor;
      Scenarios   : RTG.Scenario_Maps.Map;
      RTS_Sources : GNATCOLL.VFS.Virtual_File);

end RTG.GNAT_RTS_Sources;
