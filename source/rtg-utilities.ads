--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

with VSS.Strings;

package RTG.Utilities is

   procedure Copy_Files
     (Source_Directory : GNATCOLL.VFS.Virtual_File;
      Target_Directory : GNATCOLL.VFS.Virtual_File);

   procedure Copy_File
     (Source_Base      : GNATCOLL.VFS.Virtual_File;
      Source_Path      : VSS.Strings.Virtual_String;
      Target_Directory : GNATCOLL.VFS.Virtual_File;
      Target_Name      : VSS.Strings.Virtual_String);

end RTG.Utilities;
