--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.GNAT_RTS_Sources;

package RTG.Tasking is

   procedure Process
     (Scenarios : in out RTG.GNAT_RTS_Sources.Scenario_Maps.Map);

end RTG.Tasking;
