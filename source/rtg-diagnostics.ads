--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

with VSS.Strings;

package RTG.Diagnostics is

   procedure Error (Text : VSS.Strings.Virtual_String);

   procedure Error
     (File : GNATCOLL.VFS.Virtual_File; Text : VSS.Strings.Virtual_String);

   procedure Warning (Text : VSS.Strings.Virtual_String);

   procedure Warning
     (File : GNATCOLL.VFS.Virtual_File; Text : VSS.Strings.Virtual_String);

end RTG.Diagnostics;
