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

--  pragma Restrictions (Max_Asynchronous_Select_Nesting => 0);
--  pragma Restrictions (No_Abort_Statements);
--  pragma Restrictions (No_Exception_Propagation);
--  pragma Restrictions (No_Exception_Registration);
--  pragma Restrictions (No_Finalization);
--  pragma Restrictions (No_Implicit_Dynamic_Code);
--  pragma Restrictions (No_Specification_Of_Aspect => Attach_Handler);
--  pragma Restrictions (No_Task_At_Interrupt_Priority);
--  pragma Restrictions (No_Tasking);
--  pragma Restrictions (No_Use_Of_Pragma => Attach_Handler);

   end GCC14;

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Parameters : GCC14.System_Implementation_Parameters;
      Tasking    : RTG.Runtime.Tasking_Profile);

end RTG.System;
