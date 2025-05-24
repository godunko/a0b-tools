--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Command_Line;

with RTG.Runtime;
with RTG.System;

procedure RTG.Driver is
   Runtime    : RTG.Runtime.Runtime_Descriptor;
   Parameters : constant RTG.System.GCC14.System_Implementation_Parameters :=
     [RTG.System.GCC14.Always_Compatible_Rep     => True,
      RTG.System.GCC14.Atomic_Sync_Default       => False,
      RTG.System.GCC14.Backend_Divide_Checks     => False,
      RTG.System.GCC14.Backend_Overflow_Checks   => True,
      RTG.System.GCC14.Command_Line_Args         => False,
      RTG.System.GCC14.Configurable_Run_Times    => True,
      RTG.System.GCC14.Denorm                    => True,
      RTG.System.GCC14.Duration_32_Bits          => False,
      RTG.System.GCC14.Exit_Status_Supported     => False,
      RTG.System.GCC14.Machine_Overflows         => False,
      RTG.System.GCC14.Machine_Rounds            => True,
      RTG.System.GCC14.Preallocated_Stacks       => False,
      RTG.System.GCC14.Signed_Zeros              => True,
      RTG.System.GCC14.Stack_Check_Default       => False,
      RTG.System.GCC14.Stack_Check_Limits        => False,
      RTG.System.GCC14.Stack_Check_Probes        => False,
      RTG.System.GCC14.Support_Aggregates        => True,
      RTG.System.GCC14.Support_Atomic_Primitives => False,  --  ???
      RTG.System.GCC14.Support_Composite_Assign  => True,
      RTG.System.GCC14.Support_Composite_Compare => True,
      RTG.System.GCC14.Support_Long_Shifts       => True,
      RTG.System.GCC14.Suppress_Standard_Library => True,
      RTG.System.GCC14.Use_Ada_Main_Program_Name => False,
      RTG.System.GCC14.ZCX_By_Default            => True];
   --  It is set of parameters for ARM Cortex-M `light` runtime

   Tasking : constant RTG.Runtime.Tasking_Profile := RTG.Runtime.Light;

begin
   RTG.Runtime.Initialize (Runtime);

   RTG.Runtime.Create (Runtime, Tasking);
   RTG.System.Generate (Runtime, Parameters, Tasking);

exception
   when RTG.Internal_Error =>
      Ada.Command_Line.Set_Exit_Status (1);
end RTG.Driver;
