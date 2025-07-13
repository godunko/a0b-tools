--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.Runtime;

package RTG.System is

   package GCC14 is

      type System_Implementation_Parameter is
        (Always_Compatible_Rep,
         Atomic_Sync_Default,
         Backend_Divide_Checks,
         Backend_Overflow_Checks,
         Command_Line_Args,
         Configurable_Run_Times,
         Denorm,
         Duration_32_Bits,
         Exit_Status_Supported,
         Machine_Overflows,
         Machine_Rounds,
         Preallocated_Stacks,
         Signed_Zeros,
         Stack_Check_Default,
         Stack_Check_Limits,
         Stack_Check_Probes,
         Support_Aggregates,
         Support_Atomic_Primitives,
         Support_Composite_Assign,
         Support_Composite_Compare,
         Support_Long_Shifts,
         Suppress_Standard_Library,
         Use_Ada_Main_Program_Name,
         ZCX_By_Default);

      type System_Implementation_Parameters is
        array (System_Implementation_Parameter) of Boolean;

      type Restriction_Value_Kind is (None, Boolean, Number);

      type Restriction_Value (Kind : Restriction_Value_Kind := None) is record
         case Kind is
            when None =>
               null;

            when Boolean =>
               Applied : Standard.Boolean;

            when Number =>
               Value   : VSS.Strings.Virtual_String;
         end case;
      end record;

      type Restriction is
        (No_Abort_Statements,
         No_Exception_Propagation,
         No_Exception_Registration,
         No_Finalization,
         No_Implicit_Dynamic_Code,
         No_Task_At_Interrupt_Priority,
         No_Tasking,
         Max_Asynchronous_Select_Nesting);

      type Restrictions is array (Restriction) of Restriction_Value;

      type Profiles is (No, Ravenscar, Jorvik);

   end GCC14;

   type System_Descriptor is tagged record
      Parameters   : GCC14.System_Implementation_Parameters;
      Restrictions : GCC14.Restrictions;
      Profile      : GCC14.Profiles;
   end record;

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Descriptor);

   procedure Apply_No_Abort_Statements_Restriction
     (Descriptor : in out System_Descriptor'Class);

   procedure Apply_No_Exception_Propagation_Restriction
     (Descriptor : in out System_Descriptor'Class);

   procedure Apply_No_Exception_Registration_Restriction
     (Descriptor : in out System_Descriptor'Class);

   procedure Apply_No_Finalization_Restriction
     (Descriptor : in out System_Descriptor'Class);

   procedure Apply_No_Implicit_Dynamic_Code_Restriction
     (Descriptor : in out System_Descriptor'Class);

   procedure Apply_No_Task_At_Interrupt_Priority_Restriction
     (Descriptor : in out System_Descriptor'Class);

   procedure Apply_No_Tasking_Restriction
     (Descriptor : in out System_Descriptor'Class);

   procedure Apply_Max_Asynchronous_Select_Nesting_Restriction
     (Descriptor : in out System_Descriptor'Class;
      To         : VSS.Strings.Virtual_String);

   procedure Set_No_Abort_Statements
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True);

   procedure Set_No_Exception_Propagation
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True);

   procedure Set_No_Exception_Registration
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True);

   procedure Set_No_Finalization
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True);

   procedure Set_No_Implicit_Dynamic_Code
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True);

   procedure Set_No_Task_At_Interrupt_Priority
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True);

   procedure Set_No_Tasking
     (Descriptor : in out System_Descriptor'Class;
      To         : Boolean := True);

   procedure Set_Max_Asynchronous_Select_Nesting
     (Descriptor : in out System_Descriptor'Class;
      To         : VSS.Strings.Virtual_String);

end RTG.System;
