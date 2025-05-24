--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Output;

with RTG.Utilities;

package body RTG.Runtime is

   procedure Generate_Build_Runtime_Project (Descriptor : Runtime_Descriptor);

   procedure Generate_Build_Tasking_Project (Descriptor : Runtime_Descriptor);

   procedure Generate_Ada_Source_Path
     (Descriptor : Runtime_Descriptor;
      Tasking    : Boolean);

   procedure Generate_Ada_Object_Path
     (Descriptor : Runtime_Descriptor;
      Tasking    : Boolean);

   procedure Generate_Runtime_XML (Descriptor : Runtime_Descriptor);

   procedure Copy_Runtime_Sources (Descriptor : Runtime_Descriptor);

   procedure Copy_Tasking_Sources (Descriptor : Runtime_Descriptor);

   --------------------------
   -- Copy_Runtime_Sources --
   --------------------------

   procedure Copy_Runtime_Sources (Descriptor : Runtime_Descriptor) is
      Success : Boolean;

   begin
      --------------------
      --  Custom files  --
      --------------------

      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-macres__cortexm3.adb"),
         Descriptor.Runtime_Source_Directory.Create_From_Dir ("s-macres.adb")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-sgshca__cortexm.adb"),
         Descriptor.Runtime_Source_Directory.Create_From_Dir ("s-sgshca.adb")
           .Full_Name.all,
         Success);

      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../arm/stm32/stm32f40x/svd"),
         Descriptor.Runtime_Source_Directory.Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (GNATCOLL.VFS.Create ("../s-bbbopa.ads"),
         Descriptor.Runtime_Source_Directory.Create_From_Dir ("s-bbbopa.ads")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../arm/stm32/stm32f40x/s-bbmcpa.ads"),
         Descriptor.Runtime_Source_Directory.Create_From_Dir ("s-bbmcpa.ads")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../arm/stm32/stm32f40x/s-bbmcpa.adb"),
         Descriptor.Runtime_Source_Directory.Create_From_Dir ("s-bbmcpa.adb")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../arm/stm32/s-stm32.ads"),
         Descriptor.Runtime_Source_Directory.Create_From_Dir ("s-stm32.ads")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../arm/stm32/stm32f40x/s-stm32.adb"),
         Descriptor.Runtime_Source_Directory.Create_From_Dir ("s-stm32.adb")
           .Full_Name.all,
         Success);
   end Copy_Runtime_Sources;

   --------------------------
   -- Copy_Tasking_Sources --
   --------------------------

   procedure Copy_Tasking_Sources (Descriptor : Runtime_Descriptor) is
      Success : Boolean;

   begin
      --------------------
      --  Custom files  --
      --------------------

      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bbpara__stm32f4.ads"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bbpara.ads")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bbcppr__old.ads"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bbcppr.ads")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bbcppr__armv7m.adb"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bbcppr.adb")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bbbosu__armv7m.adb"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bbbosu.adb")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bbcpsp__arm.ads"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bbcpsp.ads")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bcpcst__pendsv.adb"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bcpcst.adb")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bcpcst__armvXm.ads"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bcpcst.ads")
           .Full_Name.all,
         Success);
      GNATCOLL.VFS.Copy
        (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
           ("/include/rts-sources/../../../src/s-bbsumu__generic.adb"),
         Descriptor.Tasking_Source_Directory.Create_From_Dir ("s-bbsumu.adb")
           .Full_Name.all,
         Success);
      --  GNATCOLL.VFS.Copy
      --    (Descriptor.GNAT_RTS_Sources_Directory.Create_From_Dir
      --       ("/include/rts-sources/"),
      --     Descriptor.Tasking_Source_Directory.Create_From_Dir ("")
      --       .Full_Name.all,
      --     Success);
   end Copy_Tasking_Sources;

   ------------
   -- Create --
   ------------

   procedure Create
     (Descriptor : Runtime_Descriptor;
      Tasking    : RTG.Runtime.Tasking_Profile) is
   begin
      Descriptor.Runtime_Directory.Make_Dir;
      Descriptor.Runtime_Source_Directory.Make_Dir;

      Generate_Ada_Source_Path (Descriptor, Tasking /= No);
      Generate_Ada_Object_Path (Descriptor, Tasking /= No);
      Generate_Build_Runtime_Project (Descriptor);
      Generate_Runtime_XML (Descriptor);
      Copy_Runtime_Sources (Descriptor);

      if Tasking /= No then
         Descriptor.Tasking_Source_Directory.Make_Dir;
         Generate_Build_Tasking_Project (Descriptor);
         Copy_Tasking_Sources (Descriptor);
      end if;
   end Create;

   ------------------------------
   -- Generate_Ada_Source_Path --
   ------------------------------

   procedure Generate_Ada_Source_Path
     (Descriptor : Runtime_Descriptor;
      Tasking    : Boolean)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.Runtime_Directory.Create_From_Dir
                ("ada_source_path").Display_Full_Name));

      Output.Put_Line ("gnat", Success);

      if Tasking then
         Output.Put_Line ("gnarl", Success);
      end if;

      Output.Close;
   end Generate_Ada_Source_Path;

   ------------------------------
   -- Generate_Ada_Object_Path --
   ------------------------------

   procedure Generate_Ada_Object_Path
     (Descriptor : Runtime_Descriptor;
      Tasking    : Boolean)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.Runtime_Directory.Create_From_Dir
                ("ada_object_path").Display_Full_Name));

      Output.Put_Line ("lib", Success);

      Output.Close;
   end Generate_Ada_Object_Path;

   ------------------------------------
   -- Generate_Build_Runtime_Project --
   ------------------------------------

   procedure Generate_Build_Runtime_Project
     (Descriptor : Runtime_Descriptor)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.Runtime_Directory.Create_From_Dir ("build_runtime.gpr")
              .Display_Full_Name));

      Output.Put_Line ("library project Build_Runtime is", Success);
      Output.Put_Line ("   for Target use ""arm-eabi"";", Success);
      Output.Put_Line
        ("   for Runtime (""Ada"") use Project'Project_Dir;", Success);
      Output.Put_Line ("   for Library_Name use ""gnat"";", Success);
      Output.Put_Line ("   for Source_Dirs use (""gnat"");", Success);
      Output.Put_Line ("   for Object_Dir use ""obj/gnat"";", Success);
      Output.Put_Line ("   for Library_Dir use ""lib"";", Success);
      Output.Put_Line ("end Build_Runtime;", Success);

      Output.Close;
   end Generate_Build_Runtime_Project;

   ------------------------------------
   -- Generate_Build_Tasking_Project --
   ------------------------------------

   procedure Generate_Build_Tasking_Project
     (Descriptor : Runtime_Descriptor)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.Runtime_Directory.Create_From_Dir ("build_tasking.gpr")
              .Display_Full_Name));

      Output.Put_Line ("library project Build_Tasking is", Success);
      Output.Put_Line ("   for Target use ""arm-eabi"";", Success);
      Output.Put_Line
        ("   for Runtime (""Ada"") use Project'Project_Dir;", Success);
      Output.Put_Line ("   for Library_Name use ""gnarl"";", Success);
      Output.Put_Line ("   for Source_Dirs use (""gnarl"");", Success);
      Output.Put_Line ("   for Object_Dir use ""obj/gnarl"";", Success);
      Output.Put_Line ("   for Library_Dir use ""lib"";", Success);
      Output.Put_Line ("end Build_Tasking;", Success);

      Output.Close;
   end Generate_Build_Tasking_Project;

   --------------------------
   -- Generate_Runtime_XML --
   --------------------------

   procedure Generate_Runtime_XML (Descriptor : Runtime_Descriptor) is
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
           (Descriptor.Runtime_Directory.Create_From_Dir
                ("runtime.xml").Display_Full_Name));

      PL ("<?xml version=""1.0""?>");
      NL;
      PL ("<gprconfig>");
      PL ("  <configuration>");
      PL ("    <config><![CDATA[");
      PL ("   package Compiler is");
      --  PL ("      Common_Required_Switches := (""-mfloat-abi=hard"", ""-mcpu=cortex-m4"", ""-mfpu=fpv4-sp-d16"");");
      PL ("      Common_Required_Switches := (""-mfloat-abi=hard"", ""-mcpu=cortex-m4"");");
      PL ("      for Leading_Required_Switches (""Ada"") use");
      PL ("        Compiler'Leading_Required_Switches (""Ada"")");
      PL ("        & Common_Required_Switches;");
      PL ("   end Compiler;");
      NL;
      PL ("   package Linker is");
      PL ("      for Required_Switches use Linker'Required_Switches &");
      PL ("        (""-nostartfiles"", ""-nolibc"");");
      PL ("   end Linker;");
      PL ("      ]]>");
      PL ("    </config>");
      PL ("  </configuration>");
      PL ("</gprconfig>");

      Output.Close;
   end Generate_Runtime_XML;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out Runtime_Descriptor) is
   begin
      Self.Runtime_Directory := GNATCOLL.VFS.Create ("rtl");
      Self.GNAT_RTS_Sources_Directory :=
        GNATCOLL.VFS.Create ("../../bb-runtimes-14/gnat_rts_sources");
   end Initialize;

   ------------------------------
   -- Runtime_Source_Directory --
   ------------------------------

   function Runtime_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File is
   begin
      return Self.Runtime_Directory.Create_From_Dir ("gnat");
   end Runtime_Source_Directory;

   ------------------------------
   -- Tasking_Source_Directory --
   ------------------------------

   function Tasking_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File is
   begin
      return Self.Runtime_Directory.Create_From_Dir ("gnarl");
   end Tasking_Source_Directory;

end RTG.Runtime;
