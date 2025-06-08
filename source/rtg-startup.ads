--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

package RTG.Startup is

   type Startup_Descriptor is tagged limited private;

   procedure Initialize (Self : in out Startup_Descriptor);

   procedure Create (Descriptor : Startup_Descriptor);

private

   type Startup_Descriptor is tagged limited record
      Startup_Directory : GNATCOLL.VFS.Virtual_File;
      A0B_ARMv7M_Prefix : GNATCOLL.VFS.Virtual_File;
   end record;

end RTG.Startup;
