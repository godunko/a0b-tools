--
--  Copyright (C) 2025-2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Style_Checks ("M90");
pragma Ada_2022;

with VSS.Strings.Formatters.Integers;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with RTG.Utilities;

package body RTG.System is

   use VSS.Strings.Formatters.Strings;
   use VSS.Strings.Templates;

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

   procedure Set
     (Value : in out GCC14.Restriction_Value;
      To    : Boolean);

   procedure Set
     (Value : in out GCC14.Restriction_Value;
      To    : VSS.Strings.Virtual_String);

   function Is_Applied
     (Descriptor  : System_Descriptor;
      Restriction : GCC14.Restriction) return Boolean;

   -------------------------------------------------------
   -- Apply_Max_Asynchronous_Select_Nesting_Restriction --
   -------------------------------------------------------

   procedure Apply_Max_Asynchronous_Select_Nesting_Restriction
     (Descriptor : in out System_Descriptor'Class;
      To         : VSS.Strings.Virtual_String) is
   begin
      Descriptor.Set_Max_Asynchronous_Select_Nesting (To);
   end Apply_Max_Asynchronous_Select_Nesting_Restriction;

   -------------------------------------------
   -- Apply_No_Abort_Statements_Restriction --
   -------------------------------------------

   procedure Apply_No_Abort_Statements_Restriction
     (Descriptor : in out System_Descriptor'Class) is
   begin
      Descriptor.Set_No_Abort_Statements (True);
   end Apply_No_Abort_Statements_Restriction;

   ------------------------------------------------
   -- Apply_No_Exception_Propagation_Restriction --
   ------------------------------------------------

   procedure Apply_No_Exception_Propagation_Restriction
     (Descriptor : in out System_Descriptor'Class) is
   begin
      Descriptor.Set_No_Exception_Propagation (True);
   end Apply_No_Exception_Propagation_Restriction;

   -------------------------------------------------
   -- Apply_No_Exception_Registration_Restriction --
   -------------------------------------------------

   procedure Apply_No_Exception_Registration_Restriction
     (Descriptor : in out System_Descriptor'Class) is
   begin
      Descriptor.Set_No_Exception_Registration (True);
   end Apply_No_Exception_Registration_Restriction;

   ---------------------------------------
   -- Apply_No_Finalization_Restriction --
   ---------------------------------------

   procedure Apply_No_Finalization_Restriction
     (Descriptor : in out System_Descriptor'Class) is
   begin
      Descriptor.Set_No_Finalization (True);
   end Apply_No_Finalization_Restriction;

   ------------------------------------------------
   -- Apply_No_Implicit_Dynamic_Code_Restriction --
   ------------------------------------------------

   procedure Apply_No_Implicit_Dynamic_Code_Restriction
     (Descriptor : in out System_Descriptor'Class) is
   begin
      Descriptor.Set_No_Implicit_Dynamic_Code (True);
   end Apply_No_Implicit_Dynamic_Code_Restriction;

   ------------------------------------------------------
   -- Apply_No_Task_At_Interrupt_Priority_Restrictions --
   ------------------------------------------------------

   procedure Apply_No_Task_At_Interrupt_Priority_Restriction
     (Descriptor : in out System_Descriptor'Class) is
   begin
      Descriptor.Set_No_Task_At_Interrupt_Priority (True);
   end Apply_No_Task_At_Interrupt_Priority_Restriction;

   ----------------------------------
   -- Apply_No_Tasking_Restriction --
   ----------------------------------

   procedure Apply_No_Tasking_Restriction
     (Descriptor : in out System_Descriptor'Class) is
   begin
      Descriptor.Set_No_Tasking (True);
   end Apply_No_Tasking_Restriction;

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Descriptor)
   is
      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Aux_Runtime_Source_Directory, "system.ads");
      use Output;

      Max_Asynchronous_Select_Nesting_Template : constant
        Virtual_String_Template :=
          "pragma Restrictions (Max_Asynchronous_Select_Nesting => {});";

      Any_Priority_Template       : constant Virtual_String_Template :=
        "   subtype Any_Priority       is Integer range      {} .. {};";
      Priority_Template           : constant Virtual_String_Template :=
        "   subtype Priority           is Any_Priority range {} .. {};";
      Interrupt_Priority_Template : constant Virtual_String_Template :=
        "   subtype Interrupt_Priority is Any_Priority range {} .. {};";
      Default_Priority_Template   : constant Virtual_String_Template :=
        "   Default_Priority : constant Priority := {};";

   begin
      if Is_Applied (Parameters, GCC14.No_Exception_Propagation) then
         PL ("pragma Restrictions (No_Exception_Propagation);");
      end if;

      if Is_Applied (Parameters, GCC14.No_Exception_Registration) then
         PL ("pragma Restrictions (No_Exception_Registration);");
      end if;

      if Is_Applied (Parameters, GCC14.No_Finalization) then
         PL ("pragma Restrictions (No_Finalization);");
      end if;

      if Is_Applied (Parameters, GCC14.No_Implicit_Dynamic_Code) then
         PL ("pragma Restrictions (No_Implicit_Dynamic_Code);");
      end if;

      if Is_Applied (Parameters, GCC14.No_Task_At_Interrupt_Priority) then
         PL ("pragma Restrictions (No_Task_At_Interrupt_Priority);");
      end if;

      if Is_Applied (Parameters, GCC14.No_Tasking) then
         PL ("pragma Restrictions (No_Tasking);");
      end if;

      if Is_Applied (Parameters, GCC14.No_Abort_Statements) then
         PL ("pragma Restrictions (No_Abort_Statements);");
      end if;

      if Is_Applied (Parameters, GCC14.Max_Asynchronous_Select_Nesting) then
         PL
           (Max_Asynchronous_Select_Nesting_Template.Format
              (Image
                 (Parameters.Restrictions
                    (GCC14.Max_Asynchronous_Select_Nesting).Value)));
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
      PL ("   Min_Int             : constant := -2 ** (Standard'Max_Integer_Size - 1);");
      PL ("   Max_Int             : constant :=  2 ** (Standard'Max_Integer_Size - 1) - 1;");
      NL;
      PL ("   Max_Binary_Modulus    : constant := 2 ** Standard'Max_Integer_Size;");
      PL ("   Max_Nonbinary_Modulus : constant := 2 ** Integer'Size - 1;");
      NL;
      PL ("   Max_Digits            : constant := Long_Float'Digits;");
      NL;
      PL ("   Max_Mantissa          : constant := Standard'Max_Integer_Size - 1;");
      NL;
      PL ("   type Address is private with Preelaborable_Initialization;");
      PL ("   Null_Address : constant Address;");
      NL;
      PL ("   Storage_Unit : constant := 8;");
      PL ("   Word_Size    : constant := 32;");
      PL ("   Memory_Size  : constant := 2 ** 32;");
      NL;
      PL ("   function ""<"" (Left, Right : Address) return Boolean");
      PL ("     with Import, Convention => Intrinsic;");
      PL ("   function ""<="" (Left, Right : Address) return Boolean");
      PL ("     with Import, Convention => Intrinsic;");
      NL;
      PL ("   type Bit_Order is (High_Order_First, Low_Order_First);");
      PL ("   Default_Bit_Order : constant Bit_Order :=");
      PL ("     Bit_Order'Val (Standard'Default_Bit_Order);");
      PL ("   pragma Warnings (Off, Default_Bit_Order);");

      --  Priorities

      declare
         Any_Priority_First       : constant Integer := 0;
         Any_Priority_Last        : constant Integer :=
           Any_Priority_First
             + Parameters.Priorities.Interrupt_Priority_Values
             + Parameters.Priorities.Priority_Values
             - 1;
         Priority_First           : constant Integer := Any_Priority_First;
         Priority_Last            : constant Integer :=
           Priority_First + Parameters.Priorities.Priority_Values - 1;
         Interrupt_Priority_First : constant Integer := Priority_Last + 1;
         Interrupt_Priority_Last  : constant Integer :=
           Interrupt_Priority_First
             + Parameters.Priorities.Interrupt_Priority_Values
             - 1;
         Default_Priority         : constant Integer :=
           (Priority_First + Priority_Last) / 2;

      begin
         NL;
         PL
           (Any_Priority_Template.Format
              (VSS.Strings.Formatters.Integers.Image (Any_Priority_First),
               VSS.Strings.Formatters.Integers.Image (Any_Priority_Last)));
         PL
           (Priority_Template.Format
              (VSS.Strings.Formatters.Integers.Image (Priority_First),
               VSS.Strings.Formatters.Integers.Image (Priority_Last)));
         PL
           (Interrupt_Priority_Template.Format
              (VSS.Strings.Formatters.Integers.Image
                 (Interrupt_Priority_First),
               VSS.Strings.Formatters.Integers.Image
                 (Interrupt_Priority_Last)));
         NL;
         PL
           (Default_Priority_Template.Format
              (VSS.Strings.Formatters.Integers.Image (Default_Priority)));
      end;

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
   end Generate;

   ----------------
   -- Is_Applied --
   ----------------

   function Is_Applied
     (Descriptor  : System_Descriptor;
      Restriction : GCC14.Restriction) return Boolean is
   begin
      case Descriptor.Restrictions (Restriction).Kind is
         when GCC14.None =>
            return False;

         when GCC14.Boolean =>
            return Descriptor.Restrictions (Restriction).Applied;

         when GCC14.Number =>
            return True;
      end case;
   end Is_Applied;

   ---------
   -- Set --
   ---------

   procedure Set
     (Value : in out GCC14.Restriction_Value;
      To    : Boolean) is
   begin
      case Value.Kind is
         when GCC14.None =>
            Value := (Kind => GCC14.Boolean, Applied => To);

         when GCC14.Boolean =>
            if Value.Applied /= To then
               raise Program_Error;
            end if;

         when others =>
            raise Program_Error;
      end case;
   end Set;

   ---------
   -- Set --
   ---------

   procedure Set
     (Value : in out GCC14.Restriction_Value;
      To    : VSS.Strings.Virtual_String)
   is
      use type VSS.Strings.Virtual_String;

   begin
      case Value.Kind is
         when GCC14.None =>
            Value := (Kind => GCC14.Number, Value => To);

         when GCC14.Number =>
            if Value.Value /= To then
               raise Program_Error;
            end if;

         when others =>
            raise Program_Error;
      end case;
   end Set;

   -----------------------------------------
   -- Set_Max_Asynchronous_Select_Nesting --
   -----------------------------------------

   procedure Set_Max_Asynchronous_Select_Nesting
     (Descriptor : in out System_Descriptor'Class;
      To         : VSS.Strings.Virtual_String) is
   begin
      Set (Descriptor.Restrictions (GCC14.Max_Asynchronous_Select_Nesting), To);
   end Set_Max_Asynchronous_Select_Nesting;

   -----------------------------
   -- Set_No_Abort_Statements --
   -----------------------------

   procedure Set_No_Abort_Statements
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Set (Descriptor.Restrictions (GCC14.No_Abort_Statements), To);
   end Set_No_Abort_Statements;

   ----------------------------------
   -- Set_No_Exception_Propagation --
   ----------------------------------

   procedure Set_No_Exception_Propagation
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Set (Descriptor.Restrictions (GCC14.No_Exception_Propagation), To);
   end Set_No_Exception_Propagation;

   -----------------------------------
   -- Set_No_Exception_Registration --
   -----------------------------------

   procedure Set_No_Exception_Registration
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Set (Descriptor.Restrictions (GCC14.No_Exception_Registration), To);
   end Set_No_Exception_Registration;

   -------------------------
   -- Set_No_Finalization --
   -------------------------

   procedure Set_No_Finalization
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Set (Descriptor.Restrictions (GCC14.No_Finalization), To);
   end Set_No_Finalization;

   ----------------------------------
   -- Set_No_Implicit_Dynamic_Code --
   ----------------------------------

   procedure Set_No_Implicit_Dynamic_Code
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Set (Descriptor.Restrictions (GCC14.No_Implicit_Dynamic_Code), To);
   end Set_No_Implicit_Dynamic_Code;

   ---------------------------------------
   -- Set_No_Task_At_Interrupt_Priority --
   ---------------------------------------

   procedure Set_No_Task_At_Interrupt_Priority
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Set (Descriptor.Restrictions (GCC14.No_Task_At_Interrupt_Priority), To);
   end Set_No_Task_At_Interrupt_Priority;

   --------------------
   -- Set_No_Tasking --
   --------------------

   procedure Set_No_Tasking
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Set (Descriptor.Restrictions (GCC14.No_Tasking), To);
   end Set_No_Tasking;

   -----------------------------
   -- Set_Preallocated_Stacks --
   -----------------------------

   procedure Set_Preallocated_Stacks
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Descriptor.Parameters (GCC14.Preallocated_Stacks) := To;
   end Set_Preallocated_Stacks;

   -----------------------------------
   -- Set_Suppress_Standard_Library --
   -----------------------------------

   procedure Set_Suppress_Standard_Library
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True) is
   begin
      Descriptor.Parameters (GCC14.Suppress_Standard_Library) := To;
   end Set_Suppress_Standard_Library;

end RTG.System;
