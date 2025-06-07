--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Style_Checks ("M90");

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Integers;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.Text_Streams.File_Output;

package body RTG.System_BB_MCU_Vectors is

   procedure Generate_Specification
     (Runtime : RTG.Runtime.Runtime_Descriptor'Class);

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
      Generate_Specification (Runtime);
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
         use VSS.Strings.Templates;

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

      Vectors0_Template      : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "   Vectors0 : constant array (Integer range -16 .. {}) of System.Address :=";
      Vector0_Template       : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "     {3} => {}_Handler'Address{}";
      Vectors_Template       : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "   Vectors : constant array (Integer range -16 .. {}) of System.Address :=";
      Vector_Template        : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "     {3} => IRQ_Handler'Address{}";
      Unspecified_Template   : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "     {3} => System.Null_Address,";

      Position               : Interrupt_Information_Vectors.Cursor;

      use RTG.System_BB_MCU_Vectors.Interrupt_Information_Vectors;

   begin
      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Runtime.Runtime_Source_Directory.Create_From_Dir
                ("s-bbmcve.adb").Display_Full_Name));

      NL;
      PL ("pragma Style_Checks (""M132"");");
      NL;
      PL ("package body System.BB.MCU_Vectors is");

      if Startup then
         NL;
         PL ("   Stack_End : constant System.Address");
         PL ("     with Import, Convention => C, External_Name => ""__stack_end"";");
      end if;

      NL;
      PL ("   procedure Dummy_Exception_Handler");
      PL ("     with Export, Convention => C, External_Name => ""Dummy_Exception_Handler"";");
      PL ("   pragma Weak_External (Dummy_Exception_Handler);");

      if Startup and Static then
         NL;
         PL ("   procedure Dummy_Interrupt_Handler");
         PL ("     with Export, Convention => C, External_Name => ""Dummy_Interrupt_Handler"";");
         PL ("   pragma Weak_External (Dummy_Interrupt_Handler);");
      end if;

      Generate_Handler_Specification
        (Name => "Reset", Is_Null => False, Kind => Import);
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
            Is_Null  => False,
            Kind     => Import,
            External => "__gnat_bkpt_trap");
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

      if GNAT_Tasking then
         Generate_Handler_Specification
           (Name     => "IRQ",
            Is_Null  => False,
            Kind     => Import,
            External => "__gnat_irq_trap",
            Weak     => False);
      end if;

      if Startup then
         if Static then
            Position := Interrupts.First;

            for J in 0 .. Interrupts.Last_Element.Value loop
               declare
                  Interrupt : constant Interrupt_Information :=
                    Interrupt_Information_Vectors.Element (Position);

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
               if Interrupt_Information_Vectors.Element (Position).Value = J
               then
                  PL
                    (Vector0_Template.Format
                       (VSS.Strings.Formatters.Integers.Image (J),
                        VSS.Strings.Formatters.Strings.Image
                          (Interrupt_Information_Vectors.Element (Position)
                             .Name),
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
                       Interrupt_Information_Vectors.Element (Position).Value
                       > J;
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
      end if;

      if GNAT_Tasking then
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
         PL ("          External_Name  => ""__vectors"";");

      end if;

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

      Output.Close;
   end Generate_Implementation;

   ----------------------------
   -- Generate_Specification --
   ----------------------------

   procedure Generate_Specification
     (Runtime : RTG.Runtime.Runtime_Descriptor'Class)
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
           (Runtime.Runtime_Source_Directory.Create_From_Dir
                ("s-bbmcve.ads").Display_Full_Name));

      NL;
      PL ("package System.BB.MCU_Vectors");
      PL ("  with Pure, Elaborate_Body, No_Elaboration_Code_All");
      PL ("is");
      NL;
      PL ("end System.BB.MCU_Vectors;");

      Output.Close;
   end Generate_Specification;

end RTG.System_BB_MCU_Vectors;
