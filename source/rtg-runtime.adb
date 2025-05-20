--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Output;

package body RTG.Runtime is

   procedure Generate_Build_Core_Project (Descriptor : Runtime_Descriptor);

   procedure Generate_Ada_Source_Path (Descriptor : Runtime_Descriptor);

   procedure Generate_Ada_Object_Path (Descriptor : Runtime_Descriptor);

   procedure Generate_Runtime_XML (Descriptor : Runtime_Descriptor);

   ------------
   -- Create --
   ------------

   procedure Create (Descriptor : Runtime_Descriptor) is
   begin
      Descriptor.RTL_Directory.Make_Dir;
      Source_Directory (Descriptor).Make_Dir;

      Generate_Ada_Source_Path (Descriptor);
      Generate_Ada_Object_Path (Descriptor);
      Generate_Build_Core_Project (Descriptor);
      Generate_Runtime_XML (Descriptor);
   end Create;

   ------------------------------
   -- Generate_Ada_Source_Path --
   ------------------------------

   procedure Generate_Ada_Source_Path (Descriptor : Runtime_Descriptor) is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.RTL_Directory.Create_From_Dir
                ("ada_source_path").Display_Full_Name));

      Output.Put_Line ("gnat", Success);

      Output.Close;
   end Generate_Ada_Source_Path;

   ------------------------------
   -- Generate_Ada_Object_Path --
   ------------------------------

   procedure Generate_Ada_Object_Path (Descriptor : Runtime_Descriptor) is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.RTL_Directory.Create_From_Dir
                ("ada_object_path").Display_Full_Name));

      Output.Put_Line ("lib/gnat", Success);

      Output.Close;
   end Generate_Ada_Object_Path;

   ---------------------------------
   -- Generate_Build_Core_Project --
   ---------------------------------

   procedure Generate_Build_Core_Project (Descriptor : Runtime_Descriptor) is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.RTL_Directory.Create_From_Dir
                ("build_core.gpr").Display_Full_Name));

      Output.Put_Line ("library project Build_Core is", Success);
      Output.Put_Line ("   for Target use ""arm-eabi"";", Success);
      Output.Put_Line
        ("   for Runtime (""Ada"") use Project'Project_Dir;", Success);
      Output.Put_Line ("   for Library_Name use ""gnat"";", Success);
      Output.Put_Line ("   for Source_Dirs use (""gnat"");", Success);
      Output.Put_Line ("   for Object_Dir use ""obj/gnat"";", Success);
      Output.Put_Line ("   for Library_Dir use ""lib/gnat"";", Success);
      Output.Put_Line ("end Build_Core;", Success);

      Output.Close;
   end Generate_Build_Core_Project;

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
           (Descriptor.RTL_Directory.Create_From_Dir
                ("runtime.xml").Display_Full_Name));

      PL ("<?xml version=""1.0""?>");
      NL;
      PL ("<gprconfig>");
      PL ("  <configuration>");
      PL ("    <config><![CDATA[");
      PL ("   package Linker is");
      PL ("      for Required_Switches use Linker'Required_Switches &");
      PL ("        (""-nostartfiles"");");
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
      Self.RTL_Directory := GNATCOLL.VFS.Create ("rtl");
   end Initialize;

     --         --------------------
     --         -- Root_Directory --
     --         --------------------
     --
     --         function Root_Directory
     --  (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   ----------------------
   -- Source_Directory --
   ----------------------

   function Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File is
   begin
      return Self.RTL_Directory.Create_From_Dir ("gnat");
   end Source_Directory;

   ----------------------
   -- Source_Directory --
   ----------------------

   function Source_Directory
     (Self : Runtime_Descriptor) return VSS.Strings.Virtual_String is
   begin
      return
        VSS.Strings.Conversions.To_Virtual_String
          (Self.Source_Directory.Display_Full_Name);
   end Source_Directory;

end RTG.Runtime;
