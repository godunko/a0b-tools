--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

with VSS.Strings;

package RTG.Runtime is

   type Runtime_Descriptor is tagged limited private;

   procedure Initialize (Self : in out Runtime_Descriptor);

   --  function Root_Directory
   --    (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   function Source_Directory
     (Self : Runtime_Descriptor) return GNATCOLL.VFS.Virtual_File;

   function Source_Directory
     (Self : Runtime_Descriptor) return VSS.Strings.Virtual_String;

   procedure Create (Descriptor : Runtime_Descriptor);

private

   type Runtime_Descriptor is tagged limited record
      RTL_Directory : GNATCOLL.VFS.Virtual_File;
   end record;

end RTG.Runtime;
