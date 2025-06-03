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
      Parameters : System_Descriptor)
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
           (Runtime.Runtime_Source_Directory.Create_From_Dir
                ("system.ads").Display_Full_Name));

      if Parameters.Restrictions (GCC14.No_Exception_Propagation) then
         PL ("pragma Restrictions (No_Exception_Propagation);");
      end if;

      if Parameters.Restrictions (GCC14.No_Exception_Registration) then
         PL ("pragma Restrictions (No_Exception_Registration);");
      end if;

      if Parameters.Restrictions (GCC14.No_Finalization) then
         PL ("pragma Restrictions (No_Finalization);");
      end if;

      if Parameters.Restrictions (GCC14.No_Implicit_Dynamic_Code) then
         PL ("pragma Restrictions (No_Implicit_Dynamic_Code);");
      end if;

      if Parameters.Restrictions (GCC14.No_Task_At_Interrupt_Priority) then
         PL ("pragma Restrictions (No_Task_At_Interrupt_Priority);");
      end if;

      if Parameters.Restrictions (GCC14.No_Tasking) then
         PL ("pragma Restrictions (No_Tasking);");
      end if;

      case Parameters.Profile is
         when GCC14.No =>
            null;

         when GCC14.Ravenscar =>
            PL ("pragma Profile (Ravenscar);");

         when GCC14.Jorvik =>
            PL ("pragma Profile (Jorvik);");
      end case;

      NL;
      PL ("package System with Pure, No_Elaboration_Code_All is");
      NL;
      PL ("   Max_Binary_Modulus    : constant := 2 ** Standard'Max_Integer_Size;");
      NL;
      PL ("   type Address is private with Preelaborable_Initialization;");
      PL ("   Null_Address : constant Address;");
      NL;
      PL ("   Storage_Unit : constant := 8;");
      PL ("   Word_Size    : constant := 32;");
      PL ("   Memory_Size  : constant := 2 ** 32;");
      NL;
      PL ("   function ""<="" (Left, Right : Address) return Boolean");
      PL ("     with Import, Convention => Intrinsic;");
      NL;
      PL ("   type Bit_Order is (High_Order_First, Low_Order_First);");
      PL ("   Default_Bit_Order : constant Bit_Order :=");
      PL ("     Bit_Order'Val (Standard'Default_Bit_Order);");
      PL ("   pragma Warnings (Off, Default_Bit_Order);");
      NL;
      PL ("   subtype Any_Priority       is Integer range         0 .. 255;");
      PL ("   subtype Priority           is Any_Priority range    0 .. 240;");
      PL ("   subtype Interrupt_Priority is Any_Priority range  241 .. 255;");
      NL;
      PL ("   Default_Priority : constant Priority := 120;");
      NL;
      PL ("private");
      NL;
      PL ("   type Address is mod Memory_Size with Size => Standard'Address_Size;");
      PL ("   Null_Address : constant Address := 0;");
      NL;

      for J in Parameters.Parameters'Range loop
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
                         (if Parameters.Parameters (J)
                            then "True" else "False"))));
         end;
      end loop;

      NL;
      PL ("end System;");

      Output.Close;
   end Generate;

end RTG.System;
