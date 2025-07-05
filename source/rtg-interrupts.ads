--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package RTG.Interrupts is

   type Interrupt_Information is record
      Name        : VSS.Strings.Virtual_String;
      Description : VSS.Strings.Virtual_String;
      Value       : Natural;
   end record;

   package Interrupt_Information_Vectors is new
     Ada.Containers.Vectors (Positive, Interrupt_Information);

end RTG.Interrupts;
