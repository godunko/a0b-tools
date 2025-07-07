--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Style_Checks ("M90");

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.Text_Streams.File_Output;

with RTG.Diagnostics;
with RTG.Tasking;
with RTG.Utilities;

package body RTG.Runtime is

   procedure Generate_Build_Libgnat_Project (Descriptor : Runtime_Descriptor);

   procedure Generate_Build_Libgnarl_Project (Descriptor : Runtime_Descriptor);

   procedure Generate_Build_Runtime_Project
     (Runtime : Runtime_Descriptor;
      Tasking : Boolean);

   procedure Generate_Ada_Source_Path
     (Descriptor : Runtime_Descriptor;
      Tasking    : Boolean);

   procedure Generate_Ada_Object_Path (Descriptor : Runtime_Descriptor);

   procedure Generate_Runtime_XML (Descriptor : Runtime_Descriptor);

   procedure Copy_Runtime_Sources (Descriptor : Runtime_Descriptor);

   procedure Copy_Tasking_Sources
     (Runtime : RTG.Runtime.Runtime_Descriptor;
      Tasking : RTG.Tasking.Tasking_Descriptor);

   --------------------------
   -- Copy_Runtime_Sources --
   --------------------------

   procedure Copy_Runtime_Sources (Descriptor : Runtime_Descriptor) is
      use type VSS.Strings.Virtual_String;

   begin
      for File of Descriptor.Runtime_Files loop
         if File.Crate /= "bb_runtimes" then
            RTG.Diagnostics.Error ("only ""bb_runtimes"" crate is supported");
         end if;

         RTG.Utilities.Copy_File
           (Descriptor.GNAT_RTS_Sources_Directory.Dir,
            File.Path,
            Descriptor.Runtime_Source_Directory,
            File.File);
      end loop;
   end Copy_Runtime_Sources;

   --------------------------
   -- Copy_Tasking_Sources --
   --------------------------

   procedure Copy_Tasking_Sources
     (Runtime : RTG.Runtime.Runtime_Descriptor;
      Tasking : RTG.Tasking.Tasking_Descriptor)
   is
      use type VSS.Strings.Virtual_String;

   begin
      for File of Tasking.Files loop
         if File.Crate /= "bb_runtimes" then
            RTG.Diagnostics.Error ("only ""bb_runtimes"" crate is supported");
         end if;

         RTG.Utilities.Copy_File
           (Runtime.GNAT_RTS_Sources_Directory.Dir,
            File.Path,
            Runtime.Tasking_Source_Directory,
            File.File);
      end loop;
   end Copy_Tasking_Sources;

   ------------
   -- Create --
   ------------

   procedure Create
     (Descriptor : Runtime_Descriptor;
      Tasking    : RTG.Tasking.Tasking_Descriptor) is
   begin
      Descriptor.Runtime_Directory.Make_Dir;
      Descriptor.Runtime_Source_Directory.Make_Dir;

      Generate_Ada_Source_Path (Descriptor, not Tasking.Kernel.Is_Empty);
      Generate_Ada_Object_Path (Descriptor);
      Generate_Build_Libgnat_Project (Descriptor);
      Generate_Build_Runtime_Project (Descriptor, not Tasking.Kernel.Is_Empty);
      Generate_Runtime_XML (Descriptor);
      Copy_Runtime_Sources (Descriptor);

      if not Tasking.Kernel.Is_Empty then
         Descriptor.Tasking_Source_Directory.Make_Dir;
         Generate_Build_Libgnarl_Project (Descriptor);
         Copy_Tasking_Sources (Descriptor, Tasking);
      end if;

      Descriptor.Startup_Source_Directory.Make_Dir;
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

   procedure Generate_Ada_Object_Path (Descriptor : Runtime_Descriptor) is
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

   -------------------------------------
   -- Generate_Build_Libgnarl_Project --
   -------------------------------------

   procedure Generate_Build_Libgnarl_Project
     (Descriptor : Runtime_Descriptor)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.Runtime_Directory.Create_From_Dir ("build_libgnarl.gpr")
              .Display_Full_Name));

      Output.Put_Line ("library project Build_Libgnarl is", Success);
      Output.Put_Line ("   for Target use ""arm-eabi"";", Success);
      Output.Put_Line
        ("   for Runtime (""Ada"") use Project'Project_Dir;", Success);
      Output.Put_Line ("   for Library_Name use ""gnarl"";", Success);
      Output.Put_Line ("   for Source_Dirs use (""gnarl"");", Success);
      Output.Put_Line ("   for Object_Dir use ""obj/gnarl"";", Success);
      Output.Put_Line ("   for Library_Dir use ""lib"";", Success);
      Output.New_Line (Success);
      Output.Put_Line ("   package Compiler is", Success);
      Output.Put_Line ("      for Switches (""Ada"") use", Success);
      Output.Put_Line ("        (""-g"",", Success);
      Output.Put_Line ("         ""-O2"",", Success);
      Output.Put_Line ("         ""-fno-delete-null-pointer-checks"",", Success);
      Output.Put_Line ("         ""-gnatg"",", Success);
      Output.Put_Line ("         ""-gnatp"",", Success);
      Output.Put_Line ("         ""-gnatn2"",", Success);
      Output.Put_Line ("         ""-nostdinc"",", Success);
      Output.Put_Line ("         ""-ffunction-sections"",", Success);
      Output.Put_Line ("         ""-fdata-sections"");", Success);
      Output.Put_Line ("   end Compiler;", Success);
      Output.New_Line (Success);
      Output.Put_Line ("end Build_Libgnarl;", Success);

      Output.Close;
   end Generate_Build_Libgnarl_Project;

   ------------------------------------
   -- Generate_Build_Libgnat_Project --
   ------------------------------------

   procedure Generate_Build_Libgnat_Project
     (Descriptor : Runtime_Descriptor)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.Runtime_Directory.Create_From_Dir ("build_libgnat.gpr")
              .Display_Full_Name));

      Output.Put_Line ("library project Build_Libgnat is", Success);
      Output.Put_Line ("   for Target use ""arm-eabi"";", Success);
      Output.Put_Line
        ("   for Runtime (""Ada"") use Project'Project_Dir;", Success);
      Output.Put_Line ("   for Library_Name use ""gnat"";", Success);
      Output.Put_Line ("   for Source_Dirs use (""gnat"");", Success);
      Output.Put_Line ("   for Object_Dir use ""obj/gnat"";", Success);
      Output.Put_Line ("   for Library_Dir use ""lib"";", Success);
      Output.New_Line (Success);
      Output.Put_Line ("   package Compiler is", Success);
      Output.Put_Line ("      for Switches (""Ada"") use", Success);
      Output.Put_Line ("        (""-g"",", Success);
      Output.Put_Line ("         ""-O2"",", Success);
      Output.Put_Line ("         ""-fno-delete-null-pointer-checks"",", Success);
      Output.Put_Line ("         ""-gnatg"",", Success);
      Output.Put_Line ("         ""-gnatp"",", Success);
      Output.Put_Line ("         ""-gnatn2"",", Success);
      Output.Put_Line ("         ""-nostdinc"",", Success);
      Output.Put_Line ("         ""-ffunction-sections"",", Success);
      Output.Put_Line ("         ""-fdata-sections"");", Success);
      Output.Put_Line ("   end Compiler;", Success);
      Output.New_Line (Success);
      Output.Put_Line ("end Build_Libgnat;", Success);

      Output.Close;
   end Generate_Build_Libgnat_Project;

   ------------------------------------
   -- Generate_Build_Runtime_Project --
   ------------------------------------

   procedure Generate_Build_Runtime_Project
     (Runtime : Runtime_Descriptor;
      Tasking : Boolean)
   is
      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Runtime_Directory, "build_runtime.gpr");
      use Output;

   begin
      NL;
      PL ("aggregate project Build_Runtime is");
      NL;
      PL ("   for Target use ""arm-eabi"";");
      PL ("   for Runtime (""Ada"") use Project'Project_Dir;");
      PL ("   for Project_Files use");
      PL ("     (""build_libgnat.gpr"",");

      if Tasking then
         PL ("      ""build_libgnarl.gpr"",");
      end if;

      PL ("      ""build_libgnast.gpr"");");
      NL;
      PL ("end Build_Runtime;");
   end Generate_Build_Runtime_Project;

   --------------------------
   -- Generate_Runtime_XML --
   --------------------------

   procedure Generate_Runtime_XML (Descriptor : Runtime_Descriptor) is
      use VSS.Strings.Formatters.Strings;
      use VSS.Strings.Templates;

      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

      procedure PL (Line : VSS.Strings.Virtual_String);

      procedure P (Text : VSS.Strings.Virtual_String);

      procedure NL;

      --------
      -- NL --
      --------

      procedure NL is
      begin
         Output.New_Line (Success);
      end NL;

      -------
      -- P --
      -------

      procedure P (Text : VSS.Strings.Virtual_String) is
      begin
         Output.Put (Text, Success);
      end P;

      --------
      -- PL --
      --------

      procedure PL (Line : VSS.Strings.Virtual_String) is
      begin
         Output.Put_Line (Line, Success);
      end PL;

      Switch_Templates : constant Virtual_String_Template :=
        """{}""";

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

      PL ("      Common_Required_Switches :=");

      for J in Descriptor.Common_Required_Switches.First_Index
                 .. Descriptor.Common_Required_Switches.Last_Index
      loop
         if J = Descriptor.Common_Required_Switches.First_Index then
            P ("        (");

         else
            PL (",");
            P ("         ");
         end if;

         P
           (Switch_Templates.Format
              (Image (Descriptor.Common_Required_Switches (J))));
      end loop;

      PL (");");

      PL ("      for Leading_Required_Switches (""Ada"") use");
      PL ("        Compiler'Leading_Required_Switches (""Ada"")");
      PL ("        & Common_Required_Switches;");
      PL ("   end Compiler;");
      NL;
      PL ("   package Linker is");
      PL ("      for Leading_Switches (""Ada"") use");
      PL ("         Linker'Leading_Switches (""Ada"")");
      PL ("         & (""${RUNTIME_DIR(ada)}/lib/libgnast.a"");");
      PL ("      for Required_Switches use");
      PL ("         Linker'Required_Switches");

      for J in Descriptor.Linker_Required_Switches.First_Index
                 .. Descriptor.Linker_Required_Switches.Last_Index
      loop
         if J = Descriptor.Linker_Required_Switches.First_Index then
            P ("         & (");

         else
            PL (",");
            P ("            ");
         end if;

         P
           (Switch_Templates.Format
              (Image (Descriptor.Linker_Required_Switches (J))));

         if J = Descriptor.Linker_Required_Switches.Last_Index then
            PL (")");
         end if;
      end loop;

      PL ("         & (""-L"", ""${RUNTIME_DIR(ada)}/gnast"",");
      PL ("            ""-T"", ""startup.ld"")");
      PL ("         & Compiler.Common_Required_Switches;");
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

   procedure Initialize
     (Self        : in out Runtime_Descriptor;
      BB_Runtimes : GNATCOLL.VFS.Virtual_File) is
   begin
      Self.Runtime_Directory          := GNATCOLL.VFS.Create ("runtime");
      Self.GNAT_RTS_Sources_Directory :=
        BB_Runtimes.Create_From_Dir ("gnat_rts_sources");
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
   -- Startup_Source_Directory --
   ------------------------------

   function Startup_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File is
   begin
      return Self.Runtime_Directory.Create_From_Dir ("gnast");
   end Startup_Source_Directory;

   ------------------------------
   -- Tasking_Source_Directory --
   ------------------------------

   function Tasking_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File is
   begin
      return Self.Runtime_Directory.Create_From_Dir ("gnarl");
   end Tasking_Source_Directory;

end RTG.Runtime;
