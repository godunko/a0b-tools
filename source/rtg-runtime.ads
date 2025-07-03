--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

with VSS.String_Vectors;

limited with RTG.Tasking;

package RTG.Runtime is

   type Runtime_Descriptor is tagged limited record
      Runtime_Directory          : GNATCOLL.VFS.Virtual_File;
      GNAT_RTS_Sources_Directory : GNATCOLL.VFS.Virtual_File;

      Common_Required_Switches   : VSS.String_Vectors.Virtual_String_Vector;
      Linker_Required_Switches   : VSS.String_Vectors.Virtual_String_Vector;
      Runtime_Files              : RTG.File_Descriptor_Vectors.Vector;
   end record;

   procedure Initialize
     (Self        : in out Runtime_Descriptor;
      BB_Runtimes : GNATCOLL.VFS.Virtual_File);

   function Runtime_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   function Tasking_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   function Startup_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   procedure Create
     (Descriptor : Runtime_Descriptor;
      Tasking    : RTG.Tasking.Tasking_Descriptor);

end RTG.Runtime;
