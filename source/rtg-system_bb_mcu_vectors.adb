--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Integers;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.Text_Streams.File_Output;

package body RTG.System_BB_MCU_Vectors is

   procedure Generate_Specification
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts : Interrupt_Information_Vectors.Vector);

   procedure Generate_Implementation
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean;
      GNAT_Tasking : Boolean);

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean;
      GNAT_Tasking : Boolean) is
   begin
      Generate_Specification (Runtime, Interrupts);
      Generate_Implementation
        (Runtime, Interrupts, Startup, Static, GNAT_Tasking);
   end Generate;

   -----------------------------
   -- Generate_Implementation --
   -----------------------------

   procedure Generate_Implementation
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean;
      GNAT_Tasking : Boolean)
   is
      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

      procedure PL (Line : VSS.Strings.Virtual_String);

      procedure PS (Item : VSS.Strings.Virtual_String);

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

      --------
      -- PS --
      --------

      procedure PS (Item : VSS.Strings.Virtual_String) is
      begin
         Output.Put (Item, Success);
      end PS;

      Vectors0_Template : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "   Vectors0 : constant array (Integer range -16 .. {}) of System.Address :=";

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Runtime.Runtime_Source_Directory.Create_From_Dir
                ("s-bbmcve.adb").Display_Full_Name));

      NL;
      PL ("package body System.BB.MCU_Vectors is");

      NL;
      PL ("   procedure Fault");
      PL ("     with Export, Convention => C, External_Name => ""fault"";");
      PL ("   pragma Weak_External (Fault);");

      if Startup then
         NL;
         PL
           (Vectors0_Template.Format
              (VSS.Strings.Formatters.Integers.Image
                 (if Static then Interrupts.Last_Element.Value else -1)));
         PL ("    (-16 => System.Null_Address,");  --  Stack
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
      end if;

      if Static then
         raise Program_Error;

      else
         PL (")");
      end if;

      PL ("     with Export,");
      PL ("          Convention     => C,");
      PL ("          Linker_Section => "".vectors"",");
      PL ("          External_Name  => ""__vectors0"";");

      NL;
      PL ("   ----------------------");
      PL ("   -- DebugMon_Handler --");
      PL ("   ----------------------");
      NL;
      PL ("   procedure DebugMon_Handler is");
      PL ("   begin");
      PL ("      loop");
      PL ("         null;");
      PL ("      end loop;");
      PL ("   end DebugMon_Handler;");

      NL;
      PL ("   -----------");
      PL ("   -- Fault --");
      PL ("   -----------");
      NL;
      PL ("   procedure Fault is");
      PL ("   begin");
      PL ("      loop");
      PL ("         null;");
      PL ("      end loop;");
      PL ("   end Fault;");

      NL;
      PL ("   --------------------");
      PL ("   -- PendSV_Handler --");
      PL ("   --------------------");
      NL;
      PL ("   procedure PendSV_Handler is");
      PL ("   begin");
      PL ("      loop");
      PL ("         null;");
      PL ("      end loop;");
      PL ("   end PendSV_Handler;");

      NL;
      PL ("   -----------------");
      PL ("   -- SVC_Handler --");
      PL ("   -----------------");
      NL;
      PL ("   procedure SVC_Handler is");
      PL ("   begin");
      PL ("      loop");
      PL ("         null;");
      PL ("      end loop;");
      PL ("   end SVC_Handler;");

      NL;
      PL ("   ---------------------");
      PL ("   -- SysTick_Handler --");
      PL ("   ---------------------");
      NL;
      PL ("   procedure SysTick_Handler is");
      PL ("   begin");
      PL ("      loop");
      PL ("         null;");
      PL ("      end loop;");
      PL ("   end SysTick_Handler;");

      NL;
      PL ("end System.BB.MCU_Vectors;");

      Output.Close;
   end Generate_Implementation;

   ----------------------------
   -- Generate_Specification --
   ----------------------------

   procedure Generate_Specification
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts : Interrupt_Information_Vectors.Vector)
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

      Vectors_Template       : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "   Vectors : constant array (Integer range -16 .. {}) of System.Address :=";
      Vector_Template        : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "     {3} => IRQ_Handler'Address{}";
      Unspecified_Template   : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "     {3} => System.Null_Address,";
      Handler_Template       : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "   procedure {}_Handler";
      Export_Template        : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "     with Export, Convention => C, External_Name => ""{}_Handler"";";
      Weak_External_Template : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "   pragma Weak_External ({}_Handler);";
      Linker_Alias_Template : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "   pragma Linker_Alias ({}_Handler, ""Dummy_Exception_Handler"");";
      Position             : Interrupt_Information_Vectors.Cursor;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Runtime.Runtime_Source_Directory.Create_From_Dir
                ("s-bbmcve.ads").Display_Full_Name));

      NL;
      PL ("package System.BB.MCU_Vectors");
      PL ("  with Pure, No_Elaboration_Code_All");
      PL ("is");

      NL;
      PL ("   procedure Reset_Handler");
      PL ("     with Import, Convention => C, External_Name => ""Reset_Handler"";");

      NL;
      PL ("   procedure NMI_Handler is null");
      PL ("     with Export, Convention => C, External_Name => ""NMI_Handler"";");
      PL ("   pragma Weak_External (NMI_Handler);");
      PL ("   pragma Linker_Alias (NMI_Handler, ""fault"");");

      NL;
      PL ("   procedure HardFault_Handler is null");
      PL ("     with Export, Convention => C, External_Name => ""HardFault_Handler"";");
      PL ("   pragma Weak_External (HardFault_Handler);");
      PL ("   pragma Linker_Alias (HardFault_Handler, ""fault"");");

      NL;
      PL ("   procedure MemManage_Handler is null");
      PL ("     with Export, Convention => C, External_Name => ""MemManage_Handler"";");
      PL ("   pragma Weak_External (MemManage_Handler);");
      PL ("   pragma Linker_Alias (MemManage_Handler, ""fault"");");

      NL;
      PL ("   procedure BusFault_Handler is null");
      PL ("     with Export, Convention => C, External_Name => ""BusFault_Handler"";");
      PL ("   pragma Weak_External (BusFault_Handler);");
      PL ("   pragma Linker_Alias (BusFault_Handler, ""fault"");");

      NL;
      PL ("   procedure UsageFault_Handler is null");
      PL ("     with Export, Convention => C, External_Name => ""UsageFault_Handler"";");
      PL ("   pragma Weak_External (UsageFault_Handler);");
      PL ("   pragma Linker_Alias (UsageFault_Handler, ""fault"");");

      NL;
      PL ("   procedure SVC_Handler");
      PL ("     with Export, Convention => C, External_Name => ""__gnat_sv_call_trap"";");
      PL ("   pragma Weak_External (SVC_Handler);");

      NL;
      PL ("   procedure DebugMon_Handler");
      PL ("     with Export, Convention => C, External_Name => ""__gnat_bkpt_trap"";");
      PL ("   pragma Weak_External (DebugMon_Handler);");

      NL;
      PL ("   procedure PendSV_Handler");
      PL ("     with Export, Convention => C, External_Name => ""__gnat_pend_sv_trap"";");
      PL ("   pragma Weak_External (PendSV_Handler);");

      NL;
      PL ("   procedure SysTick_Handler");
      PL ("     with Export, Convention => C, External_Name => ""__gnat_sys_tick_trap"";");
      PL ("   pragma Weak_External (SysTick_Handler);");

      NL;
      PL ("   procedure IRQ_Handler is null");
      PL ("     with Export, Convention => C, External_Name => ""__gnat_irq_trap"";");
      PL ("   pragma Weak_External (IRQ_Handler);");

      NL;
      PL
        (Vectors_Template.Format
           (VSS.Strings.Formatters.Integers.Image
              (Interrupts.Last_Element.Value)));
      PL ("    (-16 => System.Null_Address,");  --  Stack
      PL ("     -15 => System.Null_Address,");  --  Reset handler
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
      PL ("     -1  => SysTick_Handler'Address,");
      NL;

      Position := Interrupts.First;

      for J in 0 .. Interrupts.Last_Element.Value loop
         if Interrupt_Information_Vectors.Element (Position).Value = J then
            PL
              (Vector_Template.Format
                 (VSS.Strings.Formatters.Integers.Image (J),
                  VSS.Strings.Formatters.Strings.Image
                    (VSS.Strings.Virtual_String'
                       (if J = Interrupts.Last_Element.Value
                        then ")"
                        else ","))));

            loop
               Interrupt_Information_Vectors.Next (Position);

               exit when
                 not Interrupt_Information_Vectors.Has_Element (Position);

               exit when
                 Interrupt_Information_Vectors.Element (Position).Value > J;
            end loop;

         else
            PL
              (Unspecified_Template.Format
                 (VSS.Strings.Formatters.Integers.Image (J)));
         end if;
      end loop;

      PL ("     with Export,");
      PL ("          Convention     => C,");
      PL ("          Linker_Section => "".text"",");
      PL ("          External_Name  => ""__vectors"";");

      NL;
      PL ("end System.BB.MCU_Vectors;");

      Output.Close;
   end Generate_Specification;

end RTG.System_BB_MCU_Vectors;
