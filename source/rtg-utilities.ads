--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

package RTG.Utilities is

   procedure Copy_Files
     (Source_Directory : GNATCOLL.VFS.Virtual_File;
      Target_Directory : GNATCOLL.VFS.Virtual_File);

end RTG.Utilities;
