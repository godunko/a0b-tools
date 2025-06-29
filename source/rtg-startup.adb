--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Application;
with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Generic_Modulars;
with VSS.Strings.Templates;
with VSS.Text_Streams.File_Output;

with RTG.Diagnostics;

package body RTG.Startup is

   procedure Generate_Libstartup_Project (Descriptor : Startup_Descriptor);

   procedure Generate_Startup_Project (Descriptor : Startup_Descriptor);

   procedure Generate_Startup_Linker_Script (Descriptor : Startup_Descriptor);

   procedure Copy_Linker_Scripts (Descriptor : Startup_Descriptor);

   procedure Generate_System_Startup_Specification
     (Descriptor : Startup_Descriptor);

   procedure Generate_System_Startup_Implementation
     (Descriptor : Startup_Descriptor);

   -------------------------
   -- Copy_Linker_Scripts --
   -------------------------

   procedure Copy_Linker_Scripts (Descriptor : Startup_Descriptor) is
      Source  : constant GNATCOLL.VFS.Virtual_File :=
        Descriptor.A0B_ARMv7M_Prefix.Create_From_Dir ("source/ld/armv7m.ld");
      Success : Boolean;

   begin
      Source.Copy (Descriptor.Startup_Directory.Full_Name.all, Success);
   end Copy_Linker_Scripts;

   ------------
   -- Create --
   ------------

   procedure Create (Descriptor : Startup_Descriptor) is
   begin
      Descriptor.Startup_Directory.Make_Dir;
      Generate_Libstartup_Project (Descriptor);
      Generate_Startup_Project (Descriptor);
      Generate_Startup_Linker_Script (Descriptor);
      Copy_Linker_Scripts (Descriptor);
      Generate_System_Startup_Specification (Descriptor);
      Generate_System_Startup_Implementation (Descriptor);
   end Create;

   ---------------------------------
   -- Generate_Libstartup_Project --
   ---------------------------------

   procedure Generate_Libstartup_Project (Descriptor : Startup_Descriptor) is
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
           (Descriptor.Startup_Directory.Create_From_Dir ("libstartup.gpr")
              .Display_Full_Name));

      PL ("with ""a0b_armv7m.gpr"";");
      NL;
      PL ("library project LibStartup is");
      NL;
      PL ("   for Library_Name use ""gnatstartup"";");
      PL ("   for Library_Dir use ""lib"";");
      PL ("   for Object_Dir use "".objs"";");
      NL;
      PL ("   package Compiler is");
      PL ("      for Switches (""Ada"") use (""-g"", ""-O2"");");
      PL ("   end Compiler;");
      NL;
      PL ("end LibStartup;");

      Output.Close;
   end Generate_Libstartup_Project;

   ------------------------------------
   -- Generate_Startup_Linker_Script --
   ------------------------------------

   procedure Generate_Startup_Linker_Script
     (Descriptor : Startup_Descriptor)
   is
      use VSS.Strings.Templates;

      package Unsigned_64_Formatters is
        new VSS.Strings.Formatters.Generic_Modulars (A0B.Types.Unsigned_64);
      use Unsigned_64_Formatters;

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

      Flash_Template : constant Virtual_String_Template :=
        "    flash (rx)     : ORIGIN = 0x{:08#16}, LENGTH = 0x{:08#16}";
      SRAM_Template  : constant Virtual_String_Template :=
        "    sram (rx)      : ORIGIN = 0x{:08#16}, LENGTH = 0x{:08#16}";

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Descriptor.Startup_Directory.Create_From_Dir ("startup.ld")
              .Display_Full_Name));

      PL ("MEMORY");
      PL ("{");
      PL
        (Flash_Template.Format
           (Image (Descriptor.Flash.Address),
            Image (Descriptor.Flash.Size)));
      PL
        (SRAM_Template.Format
           (Image (Descriptor.SRAM.Address),
            Image (Descriptor.SRAM.Size)));
      PL ("}");
      NL;
      PL ("REGION_ALIAS(""DEFAULT_VECTORS"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_TEXT"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_RODATA"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_DATA"", sram);");
      PL ("REGION_ALIAS(""DEFAULT_IDATA"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_BSS"", sram);");
      PL ("REGION_ALIAS(""DEFAULT_STACK"", sram);");
      NL;
      PL ("REGION_ALIAS (""ITCM_TEXT"", sram);");
      PL ("REGION_ALIAS (""ITCM_ITEXT"", flash);");
      PL ("REGION_ALIAS (""DTCM_DATA"", sram);");
      PL ("REGION_ALIAS (""DTCM_IDATA"", flash);");
      PL ("REGION_ALIAS (""DTCM_BSS"", sram);");

      NL;
      PL ("DEFAULT_STACK_SIZE = 4 * 1024;");

      PL ("INCLUDE armv7m.ld");

      Output.Close;
   end Generate_Startup_Linker_Script;

   ------------------------------
   -- Generate_Startup_Project --
   ------------------------------

   procedure Generate_Startup_Project (Descriptor : Startup_Descriptor) is
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
           (Descriptor.Startup_Directory.Create_From_Dir ("startup.gpr")
              .Display_Full_Name));

      NL;
      PL ("with ""libstartup.gpr"";");
      NL;
      PL ("abstract project Startup is");
      NL;
      PL ("   package Linker is");
      PL ("      for Switches (""Ada"") use");
      PL ("        Linker'Required_Switches & (""-L"", Project'Project_Dir, ""-T"", ""startup.ld"");");
      PL ("   end Linker;");
      NL;
      PL ("end Startup;");

      Output.Close;
   end Generate_Startup_Project;

   --------------------------------------------
   -- Generate_System_Startup_Implementation --
   --------------------------------------------

   procedure Generate_System_Startup_Implementation
     (Descriptor : Startup_Descriptor)
   is
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
           (Descriptor.Startup_Directory.Create_From_Dir ("system_startup.adb")
              .Display_Full_Name));

      PL ("with A0B.ARMv7M.Startup_Utilities.Copy_Data_Section;");
      PL ("with A0B.ARMv7M.Startup_Utilities.Enable_FPU;");
      PL ("with A0B.ARMv7M.Startup_Utilities.Fill_BSS_Section;");
      NL;
      PL ("package body System_Startup is");
      NL;
      PL ("   procedure Reset_Handler");
      PL ("     with Export, Convention => C, External_Name => ""Reset_Handler"", No_Return;");
      NL;
      PL ("   procedure Main");
      PL ("     with Import, Convention => C, External_Name => ""main"", No_Return;");
      NL;
      PL ("   procedure Reset_Handler is");
      PL ("   begin");
      PL ("      A0B.ARMv7M.Startup_Utilities.Enable_FPU;");
      PL ("      A0B.ARMv7M.Startup_Utilities.Copy_Data_Section;");
      PL ("      A0B.ARMv7M.Startup_Utilities.Fill_BSS_Section;");
      PL ("      Main;");
      PL ("   end Reset_Handler;");
      NL;
      PL ("end System_Startup;");

      Output.Close;
   end Generate_System_Startup_Implementation;

   -------------------------------------------
   -- Generate_System_Startup_Specification --
   -------------------------------------------

   procedure Generate_System_Startup_Specification
     (Descriptor : Startup_Descriptor)
   is
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
           (Descriptor.Startup_Directory.Create_From_Dir ("system_startup.ads")
              .Display_Full_Name));

      NL;
      PL ("package System_Startup");
      PL ("  with Preelaborate, Elaborate_Body, No_Elaboration_Code_All");
      PL (" is");
      NL;
      PL ("end System_Startup;");

      Output.Close;
   end Generate_System_Startup_Specification;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out Startup_Descriptor) is
   begin
      Self.Startup_Directory := GNATCOLL.VFS.Create ("startup");

      if not VSS.Application.System_Environment.Contains
               ("A0B_ARMV7M_ALIRE_PREFIX")
      then
         RTG.Diagnostics.Error ("No `a0b_armv7m` crate");
      end if;

      Self.A0B_ARMv7M_Prefix :=
        GNATCOLL.VFS.Create
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (VSS.Application.System_Environment.Value
                   ("A0B_ARMV7M_ALIRE_PREFIX"))));

      if not Self.A0B_ARMv7M_Prefix.Is_Directory then
         RTG.Diagnostics.Error
           ("Prefix of `a0b_armv7m` crate is not directory");
      end if;
   end Initialize;

end RTG.Startup;
