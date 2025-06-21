--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Integers;
with VSS.Strings.Templates;
with VSS.Text_Streams.File_Output;

package body RTG.System_BB_MCU_Parameters is

   use VSS.Strings.Formatters.Integers;
   use VSS.Strings.Templates;

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts :
        RTG.System_BB_MCU_Vectors.Interrupt_Information_Vectors.Vector)
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

      Number_Of_Interrupts_Template : constant Virtual_String_Template :=
        "   Number_Of_Interrupts : constant := {};";

      Max_Interrupt : Natural := 0;

   begin

      for Interrupt of Interrupts loop
         Max_Interrupt := Integer'Max (@, Interrupt.Value);
      end loop;

      Output.Create
        (VSS.Strings.Conversions.To_Virtual_String
           (Runtime.Tasking_Source_Directory.Create_From_Dir
                ("s-bbmcpa.ads").Display_Full_Name));

      NL;
      PL ("package System.BB.MCU_Parameters");
      PL ("  with Preelaborate, No_Elaboration_Code_All");
      PL ("is");
      NL;
      PL (Number_Of_Interrupts_Template.Format (Image (Max_Interrupt)));
      --  PL ("   Number_Of_Interrupts : constant := 81;");
      NL;
      PL ("end System.BB.MCU_Parameters;");

      Output.Close;
   end Generate;

end RTG.System_BB_MCU_Parameters;
