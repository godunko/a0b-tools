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

      type Restriction is
        (No_Exception_Propagation,
         No_Exception_Registration,
         No_Finalization,
         No_Implicit_Dynamic_Code,
         No_Tasking);

      type Restrictions is array (Restriction) of Boolean;

      type Profiles is (No, Ravenscar, Jorvik);

   end GCC14;

   type System_Descriptor is record
      Parameters   : GCC14.System_Implementation_Parameters;
      Restrictions : GCC14.Restrictions;
      Profile      : GCC14.Profiles;
   end record;

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Parameters : System_Descriptor);

end RTG.System;
