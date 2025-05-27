--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Output;

package body RTG.System_BB_MCU_Parameters is

   --------------
   -- Generate --
   --------------

   procedure Generate (Runtime : RTG.Runtime.Runtime_Descriptor'Class) is
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
           (Runtime.Tasking_Source_Directory.Create_From_Dir
                ("s-bbmcpa.ads").Display_Full_Name));

      NL;
      PL ("package System.BB.MCU_Parameters");
      PL ("  with Preelaborate, No_Elaboration_Code_All");
      PL ("is");
      NL;
      PL ("   Number_Of_Interrupts : constant := 81;");
      NL;
      PL ("end System.BB.MCU_Parameters;");

      Output.Close;
   end Generate;

end RTG.System_BB_MCU_Parameters;
