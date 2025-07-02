--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

package RTG.Startup is

   type Parameter_Information is record
      Name  : VSS.Strings.Virtual_String;
      Path  : VSS.Strings.Virtual_String;
      Value : VSS.Strings.Virtual_String;
   end record;

   package Parameter_Information_Vectors is
     new Ada.Containers.Vectors (Positive, Parameter_Information);

   type Startup_Descriptor is tagged limited record
      Startup_Directory  : GNATCOLL.VFS.Virtual_File;
      A0B_ARMv7M_Prefix  : GNATCOLL.VFS.Virtual_File;

      Flash              : RTG.Memory_Descriptor;
      SRAM               : RTG.Memory_Descriptor;

      Project_File_Name  : VSS.Strings.Virtual_String;
      Compilation_Unit   : VSS.Strings.Virtual_String;
      Generic_Subprogram : VSS.Strings.Virtual_String;
      Parameters         : Parameter_Information_Vectors.Vector;
   end record;

   procedure Initialize (Self : in out Startup_Descriptor);

   procedure Create (Descriptor : Startup_Descriptor);

end RTG.Startup;
