--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with GNATCOLL.VFS;

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.Text_Streams.File_Output;

package body RTG.System is

   System_Implementation_Parameter_Images :
   constant array (GCC14.System_Implementation_Parameter)
     of VSS.Strings.Virtual_String :=
       [GCC14.Always_Compatible_Rep     => "Always_Compatible_Rep    ",
        GCC14.Atomic_Sync_Default       => "Atomic_Sync_Default      ",
        GCC14.Backend_Divide_Checks     => "Backend_Divide_Checks    ",
        GCC14.Backend_Overflow_Checks   => "Backend_Overflow_Checks  ",
        GCC14.Command_Line_Args         => "Command_Line_Args        ",
        GCC14.Configurable_Run_Times    => "Configurable_Run_Times   ",
        GCC14.Denorm                    => "Denorm                   ",
        GCC14.Duration_32_Bits          => "Duration_32_Bits         ",
        GCC14.Exit_Status_Supported     => "Exit_Status_Supported    ",
        GCC14.Machine_Overflows         => "Machine_Overflows        ",
        GCC14.Machine_Rounds            => "Machine_Rounds           ",
        GCC14.Preallocated_Stacks       => "Preallocated_Stacks      ",
        GCC14.Signed_Zeros              => "Signed_Zeros             ",
        GCC14.Stack_Check_Default       => "Stack_Check_Default      ",
        GCC14.Stack_Check_Limits        => "Stack_Check_Limits       ",
        GCC14.Stack_Check_Probes        => "Stack_Check_Probes       ",
        GCC14.Support_Aggregates        => "Support_Aggregates       ",
        GCC14.Support_Atomic_Primitives => "Support_Atomic_Primitives",
        GCC14.Support_Composite_Assign  => "Support_Composite_Assign ",
        GCC14.Support_Composite_Compare => "Support_Composite_Compare",
        GCC14.Support_Long_Shifts       => "Support_Long_Shifts      ",
        GCC14.Suppress_Standard_Library => "Suppress_Standard_Library",
        GCC14.Use_Ada_Main_Program_Name => "Use_Ada_Main_Program_Name",
        GCC14.ZCX_By_Default            => "ZCX_By_Default           "];

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Parameters : GCC14.System_Implementation_Parameters)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

      procedure PL (Line : VSS.Strings.Virtual_String);

      procedure NL;

      --------
      -- NL --
      --------

      procedure NL is
      begin
         Output.New_Line (Success);
      end NL;

      --------
      -- PL --
      --------

      procedure PL (Line : VSS.Strings.Virtual_String) is
      begin
         Output.Put_Line (Line, Success);
      end PL;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Runtime.Source_Directory.Create_From_Dir
                ("system.ads").Display_Full_Name));

      --  PL ("pragma Profile (Jorvik);");
      PL ("pragma Restrictions (No_Exception_Propagation);");
      PL ("pragma Restrictions (No_Exception_Registration);");
      PL ("pragma Restrictions (No_Implicit_Dynamic_Code);");
      PL ("pragma Restrictions (No_Finalization);");
      PL ("pragma Restrictions (No_Tasking);");
      NL;
      PL ("package System with Pure, No_Elaboration_Code_All is");
      NL;
      PL ("   type Address is private with Preelaborable_Initialization;");
      PL ("   Null_Address : constant Address;");
      NL;
      PL ("   Max_Binary_Modulus    : constant := 2 ** Standard'Max_Integer_Size;");
      NL;
      PL ("private");
      NL;
      PL ("   type Address is mod 2 ** 32;");
      PL ("   for Address'Size use Standard'Address_Size;");
      PL ("   Null_Address : constant Address := 0;");
      NL;

      for J in Parameters'Range loop
         declare
            Template : VSS.Strings.Templates.Virtual_String_Template :=
              "   {} : constant Boolean := {};";

         begin
            PL
              (Template.Format
                 (VSS.Strings.Formatters.Strings.Image
                      (System_Implementation_Parameter_Images (J)),
                  VSS.Strings.Formatters.Strings.Image
                    (VSS.Strings.Virtual_String'
                         (if Parameters (J) then "True" else "False"))));
         end;
      end loop;
      --  PL ("   Exit_Status_Supported     : constant Boolean := False;");
      --  PL ("   Suppress_Standard_Library : constant Boolean := True;");
      --  PL ("   Use_Ada_Main_Program_Name : constant Boolean := False;");
      NL;
      PL ("end System;");

      Output.Close;
   end Generate;

end RTG.System;
