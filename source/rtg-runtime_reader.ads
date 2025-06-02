--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

with RTG.GNAT_RTS_Sources;

package RTG.Runtime_Reader is

   procedure Read
     (File      : GNATCOLL.VFS.Virtual_File;
      Scenarios : out RTG.GNAT_RTS_Sources.Scenario_Maps.Map);

end RTG.Runtime_Reader;
