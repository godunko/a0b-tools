--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with GNATCOLL.VFS;

with RTG.Interrupts;

package RTG.SVD_Reader is

   procedure Read
     (File       : GNATCOLL.VFS.Virtual_File;
      Interrupts : out RTG.Interrupts.Interrupt_Information_Vectors.Vector);

end RTG.SVD_Reader;
