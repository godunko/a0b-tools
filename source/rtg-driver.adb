--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Command_Line;

with GNATCOLL.VFS;

with VSS.Command_Line;
with VSS.Strings.Conversions;

with RTG.GNAT_RTS_Sources;
with RTG.Runtime;
with RTG.Runtime_Reader;
with RTG.System;
with RTG.System_BB_MCU_Parameters;
with RTG.System_BB_Parameters;
with RTG.Tasking;

procedure RTG.Driver is

   BB_Runtimes_Option : constant VSS.Command_Line.Value_Option :=
     (Description => "Path to BB Runtimes sources",
      Short_Name  => <>,
      Long_Name   => "bb-runtimes",
      Value_Name  => "path");

   BB_Runtimes_Directory : GNATCOLL.VFS.Virtual_File;

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
   Scenarios : RTG.GNAT_RTS_Sources.Scenario_Maps.Map;

   Tasking : constant RTG.Runtime.Tasking_Profile := RTG.Runtime.Light;

begin
   VSS.Command_Line.Add_Option (BB_Runtimes_Option);

   VSS.Command_Line.Process;

   if VSS.Command_Line.Is_Specified (BB_Runtimes_Option) then
      BB_Runtimes_Directory :=
        GNATCOLL.VFS.Create
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (VSS.Command_Line.Value (BB_Runtimes_Option))));

      if not BB_Runtimes_Directory.Is_Directory then
         VSS.Command_Line.Report_Error
           ("Specified path of BB Runtimes is not a directory");
      end if;

   else
      VSS.Command_Line.Report_Error
        ("BB Runtimes directory is not specified");
   end if;

   RTG.Runtime.Initialize (Runtime, BB_Runtimes_Directory);

   RTG.Runtime_Reader.Read (GNATCOLL.VFS.Create ("runtime.json"), Scenarios);

   RTG.Tasking.Process (Scenarios);

   RTG.Runtime.Create (Runtime, Tasking);
   RTG.System.Generate (Runtime, Parameters, Tasking);
   RTG.System_BB_MCU_Parameters.Generate (Runtime);  --  tasking only
   RTG.System_BB_Parameters.Generate (Runtime);      --  tasking only
   RTG.GNAT_RTS_Sources.Copy
     (Runtime,
      Scenarios,
      BB_Runtimes_Directory.Create_From_Dir
        ("gnat_rts_sources/lib/gnat/rts-sources.json"));

exception
   when RTG.Internal_Error =>
      Ada.Command_Line.Set_Exit_Status (1);
end RTG.Driver;
