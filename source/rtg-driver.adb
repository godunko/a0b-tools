--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Command_Line;

with GNATCOLL.VFS;

with VSS.Application;
with VSS.Command_Line;
with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with RTG.Architecture;
with RTG.GNAT_RTS_Sources;
with RTG.Interrupts;
with RTG.Runtime;
with RTG.Runtime_Reader;
with RTG.SVD_Reader;
with RTG.Startup.Reader;
with RTG.System;
with RTG.System_BB_MCU_Parameters;
with RTG.System_BB_Parameters;
with RTG.System_BB_MCU_Vectors;
with RTG.Tasking;

procedure RTG.Driver is

   use type GNATCOLL.VFS.Virtual_File;

   BB_Runtimes_Option : constant VSS.Command_Line.Value_Option :=
     (Description => "Path to BB Runtimes sources",
      Short_Name  => <>,
      Long_Name   => "bb-runtimes",
      Value_Name  => "path");
   SVD_Option         : constant VSS.Command_Line.Value_Option :=
     (Description => "Path to SVD file",
      Short_Name  => <>,
      Long_Name   => "svd",
      Value_Name  => "path");

   BB_Runtimes_Directory : GNATCOLL.VFS.Virtual_File;
   SVD_File              : GNATCOLL.VFS.Virtual_File;
   Startup_Binding_File  : GNATCOLL.VFS.Virtual_File;

   Runtime    : RTG.Runtime.Runtime_Descriptor;
   Tasking    : RTG.Tasking.Tasking_Descriptor;
   Parameters : RTG.System.System_Descriptor :=
     (Parameters   =>
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
         RTG.System.GCC14.ZCX_By_Default            => True],
      Restrictions => [others => <>],
      Profile      => RTG.System.GCC14.No);
   --  It is set of parameters for ARM Cortex-M `light` runtime
   Scenarios  : RTG.Scenario_Maps.Map;
   Interrupts : RTG.Interrupts.Interrupt_Information_Vectors.Vector;
   System_BB_MCU_Parameters :
     RTG.System_BB_Parameters.System_BB_Parameters_Descriptor;

   Startup    : RTG.Startup.Startup_Descriptor;

begin
   VSS.Command_Line.Add_Option (BB_Runtimes_Option);
   VSS.Command_Line.Add_Option (SVD_Option);

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

   --  SVD file

   if VSS.Application.System_Environment.Contains ("A0B_TOOLS_SVD") then
      SVD_File :=
        GNATCOLL.VFS.Create_From_Base
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (VSS.Application.System_Environment.Value ("A0B_TOOLS_SVD"))),
           GNATCOLL.VFS.Get_Current_Dir.Full_Name.all);
   end if;

   if VSS.Command_Line.Is_Specified (SVD_Option) then
      SVD_File :=
        GNATCOLL.VFS.Create
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (VSS.Command_Line.Value (SVD_Option))));
   end if;

   if SVD_File = GNATCOLL.VFS.No_File then
      VSS.Command_Line.Report_Error ("SVD file not specified");

   elsif not SVD_File.Is_Regular_File then
      VSS.Command_Line.Report_Error ("SVD file not found");
   end if;

   --  Startup binding information

   if VSS.Application.System_Environment.Contains
     ("A0B_TOOLS_BINDING_STARTUP")
   then
      Startup_Binding_File :=
        GNATCOLL.VFS.Create_From_Base
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (VSS.Application.System_Environment.Value
                     ("A0B_TOOLS_BINDING_STARTUP"))),
           GNATCOLL.VFS.Get_Current_Dir.Full_Name.all);

      if not Startup_Binding_File.Is_Regular_File then
         VSS.Command_Line.Report_Error
           (VSS.Strings.Templates.To_Virtual_String_Template
              ("startup binding file {} not found").Format
                (VSS.Strings.Formatters.Strings.Image
                     (VSS.Strings.Conversions.To_Virtual_String
                        (Startup_Binding_File.Display_Full_Name))));
      end if;

   else
      VSS.Command_Line.Report_Error ("Startup binding file is not specified");
   end if;

   RTG.Runtime.Initialize (Runtime, BB_Runtimes_Directory);
   RTG.Startup.Initialize (Startup);

   --  Load files: runtime configuration, SVD file, startup binding.

   RTG.Runtime_Reader.Read
     (GNATCOLL.VFS.Create_From_Base
        ("runtime.json", GNATCOLL.VFS.Get_Current_Dir.Full_Name.all),
      Runtime,
      Tasking,
      Startup,
      Scenarios);
   RTG.SVD_Reader.Read (SVD_File, Interrupts);
   RTG.Startup.Reader.Read (Startup_Binding_File, Startup, Scenarios);

   RTG.Architecture.Process
     (Tasking, Startup, Scenarios, Parameters, System_BB_MCU_Parameters);
   RTG.Tasking.Process (Tasking, Scenarios, Parameters);

   RTG.Runtime.Create_Directories (Runtime, Tasking);
   RTG.System.Generate (Runtime, Parameters);

   if RTG.Tasking.Use_GNAT_Tasking (Tasking) then
      RTG.System_BB_MCU_Vectors.Generate (Runtime, Interrupts);
      RTG.System_BB_MCU_Parameters.Generate (Runtime, Interrupts);
      RTG.System_BB_Parameters.Generate (Runtime, System_BB_MCU_Parameters);
   end if;

   RTG.GNAT_RTS_Sources.Copy
     (Runtime,
      Tasking,
      Scenarios,
      BB_Runtimes_Directory.Create_From_Dir
        ("gnat_rts_sources/lib/gnat/rts-sources.json"));

   RTG.Runtime.Generate (Runtime, Tasking);

   RTG.Startup.Create
     (Runtime,
      Interrupts,
      Startup,
      not RTG.Tasking.Use_GNAT_Tasking (Tasking),
      RTG.Tasking.Use_GNAT_Tasking (Tasking));

exception
   when RTG.Internal_Error =>
      Ada.Command_Line.Set_Exit_Status (1);
end RTG.Driver;
