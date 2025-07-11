--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Vectors;

with VSS.Strings.Hash;

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

   package Scenario_Maps is
     new Ada.Containers.Hashed_Maps
       (Key_Type        => VSS.Strings.Virtual_String,
        Element_Type    => VSS.Strings.Virtual_String,
        Hash            => VSS.Strings.Hash,
        Equivalent_Keys => VSS.Strings."=",
        "="             => VSS.Strings."=");

   Internal_Error : exception;

end RTG;
