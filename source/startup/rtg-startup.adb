--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Style_Checks ("M100");

with VSS.Application;
with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Generic_Modulars;
with VSS.Strings.Formatters.Integers;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with RTG.Diagnostics;
with RTG.Utilities;

package body RTG.Startup is

   use VSS.Strings.Formatters.Strings;
   use VSS.Strings.Templates;

   procedure Generate_Build_Startup_Project
     (Runtime : RTG.Runtime.Runtime_Descriptor;
      Startup : Startup_Descriptor);

   procedure Generate_Startup_Linker_Script
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Descriptor : Startup_Descriptor);

   procedure Copy_Linker_Scripts
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Descriptor : Startup_Descriptor);

   procedure Generate_System_Startup_Specification
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Descriptor : Startup_Descriptor);

   procedure Generate_System_Startup_Implementation
     (Runtime      : RTG.Runtime.Runtime_Descriptor;
      Interrupts   : RTG.Interrupts.Interrupt_Information_Vectors.Vector;
      Descriptor   : Startup_Descriptor;
      Static       : Boolean;
      GNAT_Tasking : Boolean);

   -------------------------
   -- Copy_Linker_Scripts --
   -------------------------

   procedure Copy_Linker_Scripts
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Descriptor : Startup_Descriptor)
   is
      Source  : constant GNATCOLL.VFS.Virtual_File :=
        Descriptor.A0B_ARMv7M_Prefix.Create_From_Dir ("source/ld/armv7m.ld");
      Success : Boolean;

   begin
      Source.Copy (Runtime.Startup_Source_Directory .Full_Name.all, Success);
   end Copy_Linker_Scripts;

   ------------
   -- Create --
   ------------

   procedure Create
     (Runtime      : RTG.Runtime.Runtime_Descriptor;
      Interrupts   : RTG.Interrupts.Interrupt_Information_Vectors.Vector;
      Descriptor   : Startup_Descriptor;
      Static       : Boolean;
      GNAT_Tasking : Boolean) is
   begin
      Generate_Build_Startup_Project (Runtime, Descriptor);
      Generate_Startup_Linker_Script (Runtime, Descriptor);
      Copy_Linker_Scripts (Runtime, Descriptor);
      Generate_System_Startup_Specification (Runtime, Descriptor);
      Generate_System_Startup_Implementation
        (Runtime, Interrupts, Descriptor, Static, GNAT_Tasking);
   end Create;

   ------------------------------------
   -- Generate_Build_Startup_Project --
   ------------------------------------

   procedure Generate_Build_Startup_Project
     (Runtime : RTG.Runtime.Runtime_Descriptor;
      Startup : Startup_Descriptor)
   is
      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Runtime_Directory, "build_startup.gpr");
      use Output;

      With_Project_Template : constant Virtual_String_Template :=
        "with ""{}"";";

   begin
      PL ("with ""a0b_armv7m.gpr"";");
      PL (With_Project_Template.Format (Image (Startup.Project_File_Name)));
      NL;
      PL ("library project Build_Startup is");
      PL ("   for Target use ""arm-eabi"";");
      PL ("   for Runtime (""Ada"") use Project'Project_Dir;");
      PL ("   for Library_Name use ""gnast"";");
      PL ("   for Source_Dirs use (""gnast"");");
      PL ("   for Object_Dir use ""obj/gnast"";");
      PL ("   for Library_Dir use ""lib"";");
      NL;
      PL ("   package Compiler is");
      PL ("      for Switches (""Ada"") use");
      PL ("        (""-g"",");
      PL ("         ""-O2"",");
      PL ("         ""-fno-delete-null-pointer-checks"",");
      PL ("         ""-gnatg"",");
      PL ("         ""-gnatp"",");
      PL ("         ""-gnatn2"",");
      PL ("         ""-nostdinc"",");
      PL ("         ""-ffunction-sections"",");
      PL ("         ""-fdata-sections"");");
      PL ("   end Compiler;");
      NL;
      PL ("end Build_Startup;");
   end Generate_Build_Startup_Project;

   ------------------------------------
   -- Generate_Startup_Linker_Script --
   ------------------------------------

   procedure Generate_Startup_Linker_Script
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Descriptor : Startup_Descriptor)
   is
      package Unsigned_64_Formatters is
        new VSS.Strings.Formatters.Generic_Modulars (A0B.Types.Unsigned_64);
      use Unsigned_64_Formatters;

      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Startup_Source_Directory, "startup.ld");
      use Output;

      Flash_Template : constant Virtual_String_Template :=
        "    flash (rx)     : ORIGIN = 0x{:08#16}, LENGTH = 0x{:08#16}";
      SRAM_Template  : constant Virtual_String_Template :=
        "    sram (rx)      : ORIGIN = 0x{:08#16}, LENGTH = 0x{:08#16}";

   begin
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
   end Generate_Startup_Linker_Script;

   --------------------------------------------
   -- Generate_System_Startup_Implementation --
   --------------------------------------------

   procedure Generate_System_Startup_Implementation
     (Runtime      : RTG.Runtime.Runtime_Descriptor;
      Interrupts   : RTG.Interrupts.Interrupt_Information_Vectors.Vector;
      Descriptor   : Startup_Descriptor;
      Static       : Boolean;
      GNAT_Tasking : Boolean)
   is
      use RTG.Interrupts.Interrupt_Information_Vectors;

      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Startup_Source_Directory, "system_startup.adb");
      use Output;

      type External_Kind is (Import, Export);

      procedure Generate_Handler_Specification
        (Name     : VSS.Strings.Virtual_String;
         Is_Null  : Boolean                    := True;
         Kind     : External_Kind              := Export;
         External : VSS.Strings.Virtual_String :=
           VSS.Strings.Empty_Virtual_String;
         Weak     : Boolean := False;
         Alias    : VSS.Strings.Virtual_String :=
           VSS.Strings.Empty_Virtual_String);

      ------------------------------------
      -- Generate_Handler_Specification --
      ------------------------------------

      procedure Generate_Handler_Specification
        (Name     : VSS.Strings.Virtual_String;
         Is_Null  : Boolean                    := True;
         Kind     : External_Kind              := Export;
         External : VSS.Strings.Virtual_String :=
           VSS.Strings.Empty_Virtual_String;
         Weak     : Boolean := False;
         Alias    : VSS.Strings.Virtual_String :=
           VSS.Strings.Empty_Virtual_String)
      is
         Handler_Template         : constant Virtual_String_Template :=
           "   procedure {}_Handler{}";
         Export_Template          : constant Virtual_String_Template :=
           "     with {}, Convention => C, External_Name => ""{}_Handler"";";
         Export_External_Template : constant Virtual_String_Template :=
           "     with {}, Convention => C, External_Name => ""{}"";";
         Weak_External_Template   : constant Virtual_String_Template :=
           "   pragma Weak_External ({}_Handler);";
         Linker_Alias_Template    : constant Virtual_String_Template :=
           "   pragma Linker_Alias ({}_Handler, ""{}"");";

      begin
         NL;

         PL
           (Handler_Template.Format
              (Image (Name),
               Image
                 (VSS.Strings.Virtual_String'
                    (if Is_Null then " is null" else ""))));

         if External.Is_Empty then
            PL
              (Export_Template.Format
                 (Image
                    (VSS.Strings.Virtual_String'
                       (case Kind is
                          when Import => "Import",
                          when Export => "Export")),
                  Image (Name)));

         else
            PL
              (Export_External_Template.Format
                 (Image
                    (VSS.Strings.Virtual_String'
                       (case Kind is
                          when Import => "Import",
                          when Export => "Export")),
                  Image (External)));
         end if;

         if Weak then
            PL (Weak_External_Template.Format (Image (Name)));
         end if;

         if not Alias.Is_Empty then
            PL (Linker_Alias_Template.Format (Image (Name), Image (Alias)));
         end if;
      end Generate_Handler_Specification;

      With_Unit_Template     : constant Virtual_String_Template :=
        "with {};";
      Instantiation_Template : constant Virtual_String_Template :=
        "     new {}";
      Parameter_Template     : constant Virtual_String_Template :=
        "{} => {}";
      Vectors0_Template      : constant Virtual_String_Template :=
        "   Vectors0 : constant array (Integer range -16 .. {}) of System.Address :=";
      Vector0_Template       : constant Virtual_String_Template :=
        "     {3} => {}_Handler'Address{}";
      Unspecified_Template   : constant Virtual_String_Template :=
        "     {3} => System.Null_Address,";

      Position               :
        RTG.Interrupts.Interrupt_Information_Vectors.Cursor;

   begin
      NL;
      PL ("pragma Style_Checks (""M132"");");
      NL;
      PL ("with System;");
      NL;
      PL ("with A0B.ARMv7M.Startup_Utilities.Copy_Data_Section;");

      if Descriptor.ARM_Enable_FPU then
         PL ("with A0B.ARMv7M.Startup_Utilities.Enable_FPU;");
      end if;

      PL ("with A0B.ARMv7M.Startup_Utilities.Fill_BSS_Section;");
      NL;
      PL (With_Unit_Template.Format (Image (Descriptor.Compilation_Unit)));
      NL;
      PL ("package body System_Startup is");
      NL;
      PL ("   procedure Main");
      PL ("     with Import, Convention => C, External_Name => ""main"", No_Return;");
      NL;

      PL ("   procedure Configure_System_Clocks is");
      PS
        (Instantiation_Template.Format (Image (Descriptor.Generic_Subprogram)));

      for J in Descriptor.Parameters.First_Index
                 .. Descriptor.Parameters.Last_Index
      loop
         if J = Descriptor.Parameters.First_Index then
            NL;
            PS ("     (");

         else
            PS ("      ");
         end if;

         PS
           (Parameter_Template.Format
              (Image (Descriptor.Parameters (J).Name),
               Image (Descriptor.Parameters (J).Value)));

         if J = Descriptor.Parameters.Last_Index then
            PS (")");

         else
            PL (",");
         end if;
      end loop;

      PL (";");
      NL;
      PL ("   procedure Dummy_Exception_Handler");
      PL ("     with Export, Convention => C, External_Name => ""Dummy_Exception_Handler"";");
      PL ("   pragma Weak_External (Dummy_Exception_Handler);");

      if Static then
         NL;
         PL ("   procedure Dummy_Interrupt_Handler");
         PL ("     with Export, Convention => C, External_Name => ""Dummy_Interrupt_Handler"";");
         PL ("   pragma Weak_External (Dummy_Interrupt_Handler);");
      end if;

      Generate_Handler_Specification
        (Name => "Reset", Is_Null => False);
      Generate_Handler_Specification
        (Name => "NMI", Weak => True, Alias => "Dummy_Exception_Handler");
      Generate_Handler_Specification
        (Name => "HardFault", Weak => True, Alias => "Dummy_Exception_Handler");
      Generate_Handler_Specification
        (Name => "MemManage", Weak => True, Alias => "Dummy_Exception_Handler");
      Generate_Handler_Specification
        (Name => "BusFault", Weak => True, Alias => "Dummy_Exception_Handler");
      Generate_Handler_Specification
        (Name  => "UsageFault",
         Weak  => True,
         Alias => "Dummy_Exception_Handler");

      if GNAT_Tasking then
         Generate_Handler_Specification
           (Name     => "SVC",
            Is_Null  => False,
            Kind     => Import,
            External => "__gnat_sv_call_trap");
         Generate_Handler_Specification
           (Name     => "DebugMon",
            External => "__gnat_bkpt_trap",
            Weak     => True,
            Alias    => "Dummy_Exception_Handler");
         Generate_Handler_Specification
           (Name     => "PendSV",
            Is_Null  => False,
            Kind     =>  Import,
            External => "__gnat_pend_sv_trap");
         Generate_Handler_Specification
           (Name     => "SysTick",
            Is_Null  => False,
            Kind     => Import,
            External => "__gnat_sys_tick_trap");

      else
         Generate_Handler_Specification
           (Name => "SVC", Weak => True, Alias => "Dummy_Exception_Handler");
         Generate_Handler_Specification
           (Name  => "DebugMon",
            Weak  => True,
            Alias => "Dummy_Exception_Handler");
         Generate_Handler_Specification
           (Name => "PendSV", Weak => True, Alias => "Dummy_Exception_Handler");
         Generate_Handler_Specification
           (Name  => "SysTick",
            Weak  => True,
            Alias => "Dummy_Exception_Handler");
      end if;

      if Static then
         Position := Interrupts.First;

         for J in 0 .. Interrupts.Last_Element.Value loop
            declare
               Interrupt : constant
                 RTG.Interrupts.Interrupt_Information :=
                   Element (Position);

            begin
               if Interrupt.Value = J then
                  Generate_Handler_Specification
                    (Name  => Interrupt.Name,
                     Weak  => True,
                     Alias => "Dummy_Interrupt_Handler");

                  loop
                     Next (Position);

                     exit when not Has_Element (Position);

                     exit when Element (Position).Value > J;
                  end loop;
               end if;
            end;
         end loop;
      end if;

      NL;
      PL ("   Stack_End : constant System.Address");
      PL ("     with Import, Convention => C, External_Name => ""__stack_end"";");

      NL;
      PL
        (Vectors0_Template.Format
           (VSS.Strings.Formatters.Integers.Image
               (if Static then Interrupts.Last_Element.Value else -1)));
      PL ("    (-16 => Stack_End'Address,");
      PL ("     -15 => Reset_Handler'Address,");
      PL ("     -14 => NMI_Handler'Address,");
      PL ("     -13 => HardFault_Handler'Address,");
      PL ("     -12 => MemManage_Handler'Address,");
      PL ("     -11 => BusFault_Handler'Address,");
      PL ("     -10 => UsageFault_Handler'Address,");
      PL ("     -9  => System.Null_Address,");
      PL ("     -8  => System.Null_Address,");
      PL ("     -7  => System.Null_Address,");
      PL ("     -6  => System.Null_Address,");
      PL ("     -5  => SVC_Handler'Address,");
      PL ("     -4  => DebugMon_Handler'Address,");
      PL ("     -3  => System.Null_Address,");
      PL ("     -2  => PendSV_Handler'Address,");
      PS ("     -1  => SysTick_Handler'Address");

      if Static then
         PL (",");

         Position := Interrupts.First;

         for J in 0 .. Interrupts.Last_Element.Value loop
            if Element (Position).Value = J then
               PL
                 (Vector0_Template.Format
                    (VSS.Strings.Formatters.Integers.Image (J),
                     VSS.Strings.Formatters.Strings.Image
                       (Element (Position).Name),
                     VSS.Strings.Formatters.Strings.Image
                       (VSS.Strings.Virtual_String'
                          (if J = Interrupts.Last_Element.Value
                           then ")"
                           else ","))));

               loop
                  Next (Position);

                  exit when not Has_Element (Position);

                  exit when Element (Position).Value > J;
               end loop;

            else
               PL
                 (Unspecified_Template.Format
                    (VSS.Strings.Formatters.Integers.Image (J)));
            end if;
         end loop;

      else
         PL (")");
      end if;

      PL ("     with Export,");
      PL ("          Convention     => C,");
      PL ("          Linker_Section => "".vectors"",");
      PL ("          External_Name  => ""__vectors0"";");
      --  Alignment of the initial interrupt vector table is enforced by the
      --  linker script.

      NL;
      PL ("   -----------------------------");
      PL ("   -- Dummy_Exception_Handler --");
      PL ("   -----------------------------");
      NL;
      PL ("   procedure Dummy_Exception_Handler is");
      PL ("   begin");
      PL ("      loop");
      PL ("         null;");
      PL ("      end loop;");
      PL ("   end Dummy_Exception_Handler;");

      if Static then
         NL;
         PL ("   -----------------------------");
         PL ("   -- Dummy_Interrupt_Handler --");
         PL ("   -----------------------------");
         NL;
         PL ("   procedure Dummy_Interrupt_Handler is");
         PL ("   begin");
         PL ("      loop");
         PL ("         null;");
         PL ("      end loop;");
         PL ("   end Dummy_Interrupt_Handler;");
      end if;

      NL;
      PL ("   procedure Reset_Handler is");
      PL ("   begin");

      if Descriptor.ARM_Enable_FPU then
         PL ("      A0B.ARMv7M.Startup_Utilities.Enable_FPU;");
      end if;

      PL ("      A0B.ARMv7M.Startup_Utilities.Copy_Data_Section;");
      PL ("      A0B.ARMv7M.Startup_Utilities.Fill_BSS_Section;");
      PL ("      Configure_System_Clocks;");
      PL ("      Main;");
      PL ("   end Reset_Handler;");
      NL;
      PL ("end System_Startup;");
   end Generate_System_Startup_Implementation;

   -------------------------------------------
   -- Generate_System_Startup_Specification --
   -------------------------------------------

   procedure Generate_System_Startup_Specification
     (Runtime    : RTG.Runtime.Runtime_Descriptor;
      Descriptor : Startup_Descriptor)
   is

      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Startup_Source_Directory, "system_startup.ads");
      use Output;

   begin
      NL;
      PL ("package System_Startup");
      PL ("  with Elaborate_Body, No_Elaboration_Code_All");
      PL ("is");
      NL;
      PL ("end System_Startup;");
   end Generate_System_Startup_Specification;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out Startup_Descriptor) is
   begin
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
