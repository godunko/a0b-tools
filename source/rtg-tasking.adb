--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with VSS.Strings.Templates;

with RTG.Diagnostics;

package body RTG.Tasking is

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
      if not Scenarios.Contains ("tasking")
        or else Scenarios ("tasking") = "no"
      then
         RTG.Diagnostics.Warning
           ("""tasking"" is not specified, assume ""light""");
         Check_Set ("RTS_Profile", "light");
         System_Parameters.Profile := RTG.System.GCC14.No;
         System_Parameters.Restrictions :=
           [RTG.System.GCC14.No_Exception_Propagation  => True,
            RTG.System.GCC14.No_Exception_Registration => True,
            RTG.System.GCC14.No_Finalization           => True,
            RTG.System.GCC14.No_Implicit_Dynamic_Code  => True,
            RTG.System.GCC14.No_Tasking                => True];

      elsif Scenarios ("tasking") = "light" then
         Check_Set ("RTS_Profile", "light-tasking");
         System_Parameters.Profile := RTG.System.GCC14.Jorvik;
         System_Parameters.Restrictions :=
           [RTG.System.GCC14.No_Exception_Propagation  => True,
            RTG.System.GCC14.No_Exception_Registration => True,
            RTG.System.GCC14.No_Finalization           => True,
            RTG.System.GCC14.No_Implicit_Dynamic_Code  => True,
            RTG.System.GCC14.No_Tasking                => False];

      elsif Scenarios ("tasking") = "embedded" then
         Check_Set ("RTS_Profile", "embedded");
         System_Parameters.Profile := RTG.System.GCC14.Jorvik;
         System_Parameters.Restrictions :=
           [RTG.System.GCC14.No_Exception_Propagation  => False,
            RTG.System.GCC14.No_Exception_Registration => True,
            RTG.System.GCC14.No_Finalization           => False,
            RTG.System.GCC14.No_Implicit_Dynamic_Code  => False,
            RTG.System.GCC14.No_Tasking                => False];

      else
         RTG.Diagnostics.Error ("unknown tasking");
      end if;
   end Process;

end RTG.Tasking;
