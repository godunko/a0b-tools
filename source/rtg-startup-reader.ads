--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.GNAT_RTS_Sources;

package RTG.Startup.Reader is

   procedure Read
     (File      : GNATCOLL.VFS.Virtual_File;
      Startup   : in out RTG.Startup.Startup_Descriptor;
      Scenarios : RTG.GNAT_RTS_Sources.Scenario_Maps.Map);

end RTG.Startup.Reader;
