--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

package RTG.Runtime is

   type Runtime_Descriptor is tagged limited private;

   procedure Initialize
     (Self        : in out Runtime_Descriptor;
      BB_Runtimes : GNATCOLL.VFS.Virtual_File);

   --  function Root_Directory
   --    (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   function Runtime_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   function Tasking_Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   procedure Create
     (Descriptor : Runtime_Descriptor;
      Tasking    : Boolean);

private

   type Runtime_Descriptor is tagged limited record
      Runtime_Directory          : GNATCOLL.VFS.Virtual_File;
      GNAT_RTS_Sources_Directory : GNATCOLL.VFS.Virtual_File;
   end record;

end RTG.Runtime;
