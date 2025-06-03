--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Templates;

with RTG.Diagnostics;
with RTG.Tasking;

package body RTG.Architecture is

   -------------
   -- Process --
   -------------

   procedure Process
     (Scenarios         : in out RTG.GNAT_RTS_Sources.Scenario_Maps.Map;
      System_Parameters : in out RTG.System.System_Descriptor)
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
      if not Scenarios.Contains ("dt:cpu") then
         RTG.Diagnostics.Error ("""dt:cpu"" is not specified");

      elsif Scenarios ("dt:cpu") = "arm,cortex-m4f" then
         Check_Set ("CPU_Family", "arm");
         Check_Set ("Target_Word_Size", "32");
         Check_Set ("Has_FMA", "no");
         Check_Set ("Has_Compare_And_Swap", "yes");
         Check_Set ("Has_CHERI", "no");

         if RTG.Tasking.Use_GNAT_Tasking (Scenarios) then
            System_Parameters.Restrictions
              (RTG.System.GCC14.No_Task_At_Interrupt_Priority) := True;
         end if;

      else
         RTG.Diagnostics.Error ("unsupported ""dt:cpu""");
      end if;
   end Process;

end RTG.Architecture;
