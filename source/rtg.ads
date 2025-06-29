--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Containers.Vectors;

with VSS.Strings;

with A0B.Types;

package RTG with Preelaborate is

   type File_Descriptor is record
      File  : VSS.Strings.Virtual_String;
      Crate : VSS.Strings.Virtual_String;
      Path  : VSS.Strings.Virtual_String;
   end record;

   package File_Descriptor_Vectors is
     new Ada.Containers.Vectors (Positive, File_Descriptor);

   type Memory_Descriptor is record
      Address : A0B.Types.Unsigned_64;
      Size    : A0B.Types.Unsigned_64;
   end record;

   Internal_Error : exception;

end RTG;
