--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Containers.Hashed_Maps;

with GNATCOLL.VFS;

with VSS.Strings.Hash;

with RTG.Runtime;
limited with RTG.Tasking;

package RTG.GNAT_RTS_Sources is

   package Scenario_Maps is
     new Ada.Containers.Hashed_Maps
       (Key_Type        => VSS.Strings.Virtual_String,
        Element_Type    => VSS.Strings.Virtual_String,
        Hash            => VSS.Strings.Hash,
        Equivalent_Keys => VSS.Strings."=",
        "="             => VSS.Strings."=");

   procedure Copy
     (Runtime     : RTG.Runtime.Runtime_Descriptor'Class;
      Tasking     : RTG.Tasking.Tasking_Descriptor;
      Scenarios   : Scenario_Maps.Map;
      RTS_Sources : GNATCOLL.VFS.Virtual_File);

end RTG.GNAT_RTS_Sources;
