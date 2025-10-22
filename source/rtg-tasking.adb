--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with VSS.Strings.Templates;

with RTG.Diagnostics;

package body RTG.Tasking is

   use type VSS.Strings.Virtual_String;

   -------------
   -- Process --
   -------------

   procedure Process
     (Tasking           : RTG.Tasking.Tasking_Descriptor;
      Scenarios         : in out RTG.Scenario_Maps.Map;
      System_Parameters : in out RTG.System.System_Descriptor)
   is
      use all type RTG.System.GCC14.System_Implementation_Parameter;

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
      if Tasking.Kernel.Is_Empty then
         Check_Set ("RTS_Profile", "light");
         System_Parameters.Profile := RTG.System.GCC14.No;
         System_Parameters.Apply_No_Exception_Propagation_Restriction;
         System_Parameters.Apply_No_Exception_Registration_Restriction;
         System_Parameters.Apply_No_Implicit_Dynamic_Code_Restriction;
         System_Parameters.Apply_No_Tasking_Restriction;

         System_Parameters.Apply_Max_Asynchronous_Select_Nesting_Restriction
           ("0");
         System_Parameters.Apply_No_Abort_Statements_Restriction;
         --  XXX GCC15: These are necessary to suppress use of
         --  `System.Standard_Library.Abort_Undefer_Direct` subprogram.

         System_Parameters.Parameters (Preallocated_Stacks)       := False;
         System_Parameters.Parameters (Suppress_Standard_Library) := True;

      elsif Tasking.Kernel = "light" then
         Check_Set ("RTS_Profile", "light-tasking");
         System_Parameters.Profile := RTG.System.GCC14.Jorvik;
         System_Parameters.Apply_No_Exception_Propagation_Restriction;
         System_Parameters.Apply_No_Exception_Registration_Restriction;
         System_Parameters.Apply_No_Implicit_Dynamic_Code_Restriction;

         System_Parameters.Apply_Max_Asynchronous_Select_Nesting_Restriction
           ("0");
         System_Parameters.Apply_No_Abort_Statements_Restriction;
         --  XXX GCC15: These are necessary to suppress use of
         --  `System.Standard_Library.Abort_Undefer_Direct` subprogram.

         System_Parameters.Parameters (Preallocated_Stacks)       := True;
         System_Parameters.Parameters (Suppress_Standard_Library) := True;

      elsif Tasking.Kernel = "embedded" then
         Check_Set ("RTS_Profile", "embedded");
         System_Parameters.Profile := RTG.System.GCC14.Jorvik;

         System_Parameters.Parameters (Preallocated_Stacks)       := True;
         System_Parameters.Parameters (Suppress_Standard_Library) := False;

      elsif Tasking.Kernel = "custom" then
         System_Parameters.Profile := RTG.System.GCC14.Jorvik;
         System_Parameters.Apply_No_Exception_Propagation_Restriction;
         System_Parameters.Apply_No_Exception_Registration_Restriction;
         System_Parameters.Apply_No_Implicit_Dynamic_Code_Restriction;
         --  System_Parameters.Apply_No_Tasking_Restriction;

         System_Parameters.Apply_Max_Asynchronous_Select_Nesting_Restriction
           ("0");
         System_Parameters.Apply_No_Abort_Statements_Restriction;
         --  XXX GCC15: These are necessary to suppress use of
         --  `System.Standard_Library.Abort_Undefer_Direct` subprogram.

         System_Parameters.Parameters (Preallocated_Stacks)       := False;
         System_Parameters.Parameters (Suppress_Standard_Library) := True;

      else
         RTG.Diagnostics.Error ("unknown tasking");
      end if;
   end Process;

   ----------------------
   -- Use_GNAT_Tasking --
   ----------------------

   function Use_GNAT_Tasking
     (Tasking : RTG.Tasking.Tasking_Descriptor) return Boolean is
   begin
      return Tasking.Kernel = "light" or Tasking.Kernel = "embedded";
   end Use_GNAT_Tasking;

end RTG.Tasking;
