--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Templates;

with RTG.Diagnostics;

package body RTG.Tasking is

   -------------
   -- Process --
   -------------

   procedure Process
     (Scenarios : in out RTG.GNAT_RTS_Sources.Scenario_Maps.Map)
   is
      use type VSS.Strings.Virtual_String;

      procedure Check_Set
        (Name  : VSS.Strings.Virtual_String;
         Value : VSS.Strings.Virtual_String);

      ---------------
      -- Check_Set --
      ---------------

      procedure Check_Set
        (Name  : VSS.Strings.Virtual_String;
         Value : VSS.Strings.Virtual_String)
      is
         Template : constant VSS.Strings.Templates.Virtual_String_Template :=
           "scenario ""{}"" is set to ""{}"", expected ""{}""";

      begin
         if Scenarios.Contains (Name) then
            if Scenarios (Name) /= Value then
               RTG.Diagnostics.Error (Template, Name, Scenarios (Name), Value);
            end if;

         else
            Scenarios.Insert (Name, Value);
         end if;
      end Check_Set;

   begin
      if not Scenarios.Contains ("tasking") then
         RTG.Diagnostics.Warning
           ("""tasking"" is not specified, assume ""light""");
         Check_Set ("RTS_Profile", "light");

      elsif Scenarios ("tasking") = "no" then
         Check_Set ("RTS_Profile", "light");

      elsif Scenarios ("tasking") = "light" then
         Check_Set ("RTS_Profile", "light-tasking");

      elsif Scenarios ("tasking") = "embedded" then
         Check_Set ("RTS_Profile", "embedded");

      else
         RTG.Diagnostics.Error ("unknown tasking");
      end if;
   end Process;

end RTG.Tasking;
