--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Containers.Vectors;

with VSS.Strings;

with RTG.Runtime;

package RTG.System_BB_MCU_Vectors is

   type Interrupt_Information is record
      Name        : VSS.Strings.Virtual_String;
      Description : VSS.Strings.Virtual_String;
      Value       : Natural;
   end record;

   package Interrupt_Information_Vectors is new
     Ada.Containers.Vectors (Positive, Interrupt_Information);

   procedure Generate
     (Runtime      : RTG.Runtime.Runtime_Descriptor'Class;
      Interrupts   : Interrupt_Information_Vectors.Vector;
      Startup      : Boolean;
      Static       : Boolean;
      GNAT_Tasking : Boolean);
   --  Generates `System.BB.MCU_Interrupts` package, which contains
   --  declarations of interrupt vector table(s).
   --
   --  @param Startup       Generate startup vector table (ARMv7)
   --  @param Static        Extend startup vector table by MCU's interrupts
   --  @param GNAT_Tasking  Generate vector table for GNAT tasking

end RTG.System_BB_MCU_Vectors;
