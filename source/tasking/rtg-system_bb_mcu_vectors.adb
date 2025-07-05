--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Style_Checks ("M100");

with VSS.Strings.Formatters.Integers;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with A0B.Types.GCC_Builtins;

with RTG.Utilities;

package body RTG.System_BB_MCU_Vectors is

   procedure Generate_Specification
     (Runtime : RTG.Runtime.Runtime_Descriptor'Class);

   procedure Generate_Implementation
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean);

   function Vector_Table_Alignment
     (Interrupts : Interrupt_Information_Vectors.Vector) return Positive;
   --  Compute alignment of the interrupt vector table for ARM Cortex-M CPU

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean) is
   begin
      Generate_Specification (Runtime);
      Generate_Implementation (Runtime, Interrupts, Startup, Static);
   end Generate;

   -----------------------------
   -- Generate_Implementation --
   -----------------------------

   procedure Generate_Implementation
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean)
   is
      use RTG.System_BB_MCU_Vectors.Interrupt_Information_Vectors;
      use VSS.Strings.Templates;

      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Runtime_Source_Directory, "s-bbmcve.adb");
      use Output;

      type External_Kind is (Import, Export);

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
         use VSS.Strings.Formatters.Strings;

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

      Vectors_Template       : constant Virtual_String_Template :=
        "   Vectors : constant array (Integer range -16 .. {}) of System.Address :=";
      Vector_Template        : constant Virtual_String_Template :=
        "     {3} => IRQ_Handler'Address{}";
      Unspecified_Template   : constant Virtual_String_Template :=
        "     {3} => System.Null_Address,";
      Alignment_Template     : constant Virtual_String_Template :=
        "          Alignment      => {};";

      Position               : Interrupt_Information_Vectors.Cursor;

   begin
      NL;
      PL ("pragma Style_Checks (""M132"");");
      NL;
      PL ("package body System.BB.MCU_Vectors is");

      NL;
      PL ("   procedure Dummy_Exception_Handler");
      PL ("     with Export, Convention => C, External_Name => ""Dummy_Exception_Handler"";");
      PL ("   pragma Weak_External (Dummy_Exception_Handler);");

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

      Generate_Handler_Specification
        (Name     => "IRQ",
         Is_Null  => False,
         Kind     => Import,
         External => "__gnat_irq_trap",
         Weak     => False);

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
         declare
            Interrupt : constant Interrupt_Information :=
              Interrupt_Information_Vectors.Element (Position);

         begin
            if Interrupt.Value = J then
               PL
                 (Vector_Template.Format
                    (VSS.Strings.Formatters.Integers.Image (J),
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
         end;
      end loop;

      PL ("     with Export,");
      PL ("          Convention     => C,");
      PL ("          Linker_Section => "".text"",");
      PL ("          External_Name  => ""__vectors"",");
      PL
        (Alignment_Template.Format
           (VSS.Strings.Formatters.Integers.Image
                (Vector_Table_Alignment (Interrupts))));

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
      PL ("end System.BB.MCU_Vectors;");
   end Generate_Implementation;

   ----------------------------
   -- Generate_Specification --
   ----------------------------

   procedure Generate_Specification
     (Runtime : RTG.Runtime.Runtime_Descriptor'Class)
   is
      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Runtime_Source_Directory, "s-bbmcve.ads");
      use Output;

   begin
      NL;
      PL ("package System.BB.MCU_Vectors");
      PL ("  with Pure, Elaborate_Body, No_Elaboration_Code_All");
      PL ("is");
      NL;
      PL ("end System.BB.MCU_Vectors;");
   end Generate_Specification;

   ----------------------------
   -- Vector_Table_Alignment --
   ----------------------------

   function Vector_Table_Alignment
     (Interrupts : Interrupt_Information_Vectors.Vector) return Positive
   is
      Minimum_Power_Of_Two : constant Positive :=
        32 -
          Positive
            (A0B.Types.GCC_Builtins.clz
               (A0B.Types.Unsigned_32
                  (Interrupts.Last_Element.Value + 16)));

   begin
      return 2 ** (Minimum_Power_Of_Two + 2);
   end Vector_Table_Alignment;

end RTG.System_BB_MCU_Vectors;
