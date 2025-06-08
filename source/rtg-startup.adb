--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Application;
with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Output;

with RTG.Diagnostics;

package body RTG.Startup is

   procedure Generate_Startup_Project (Descriptor : Startup_Descriptor);

   procedure Generate_Startup_Linker_Script (Descriptor : Startup_Descriptor);

   procedure Copy_Linker_Scripts (Descriptor : Startup_Descriptor);

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
      Generate_Startup_Project (Descriptor);
      Generate_Startup_Linker_Script (Descriptor);
      Copy_Linker_Scripts (Descriptor);
   end Create;

   ------------------------------------
   -- Generate_Startup_Linker_Script --
   ------------------------------------

   procedure Generate_Startup_Linker_Script (Descriptor : Startup_Descriptor) is
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
           (Descriptor.Startup_Directory.Create_From_Dir ("startup.ld")
              .Display_Full_Name));

      PL ("MEMORY");
      PL ("{");
      PL ("    flash (rx)     : ORIGIN = 0x08000000, LENGTH = 512K");
      PL ("    ccm_sram (xrw) : ORIGIN = 0x10000000, LENGTH = 32K");
      PL ("    sram1 (xrw)    : ORIGIN = 0x20000000, LENGTH = 80K");
      PL ("    sram2 (xrw)    : ORIGIN = 0x20014000, LENGTH = 16K");
      PL ("}");
      NL;
      PL ("REGION_ALIAS(""DEFAULT_VECTORS"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_TEXT"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_RODATA"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_DATA"", sram1);");
      PL ("REGION_ALIAS(""DEFAULT_IDATA"", flash);");
      PL ("REGION_ALIAS(""DEFAULT_BSS"", sram1);");
      PL ("REGION_ALIAS(""DEFAULT_STACK"", sram2);");
      NL;
      PL ("REGION_ALIAS (""ITCM_TEXT"", ccm_sram);");
      PL ("REGION_ALIAS (""ITCM_ITEXT"", flash);");
      PL ("REGION_ALIAS (""DTCM_DATA"", ccm_sram);");
      PL ("REGION_ALIAS (""DTCM_IDATA"", flash);");
      PL ("REGION_ALIAS (""DTCM_BSS"", ccm_sram);");

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
      PL ("project Startup is");
      NL;
      PL ("   package Linker is");
      PL ("      for Switches (""Ada"") use");
      PL ("        Linker'Required_Switches & (""-T"", ""startup.ld"");");
      PL ("   end Linker;");
      NL;
      PL ("end Startup;");

      Output.Close;
   end Generate_Startup_Project;

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
