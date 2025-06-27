--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Containers.Vectors;

with VSS.Strings;

package RTG with Preelaborate is

   type File_Descriptor is record
      File  : VSS.Strings.Virtual_String;
      Crate : VSS.Strings.Virtual_String;
      Path  : VSS.Strings.Virtual_String;
   end record;

   package File_Descriptor_Vectors is
     new Ada.Containers.Vectors (Positive, File_Descriptor);

   Internal_Error : exception;

end RTG;
