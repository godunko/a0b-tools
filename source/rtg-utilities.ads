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

   procedure Copy_File
     (Source_Base      : GNATCOLL.VFS.Virtual_File;
      Source_Path      : VSS.Strings.Virtual_String;
      Target_Directory : GNATCOLL.VFS.Virtual_File;
      Target_Name      : VSS.Strings.Virtual_String);

   procedure Synchronize
     (Source_Directory : GNATCOLL.VFS.Virtual_File;
      Target_Directory : GNATCOLL.VFS.Virtual_File);

   generic
      Directory : GNATCOLL.VFS.Virtual_File;
      File_Name : VSS.Strings.Virtual_String;

   package Generic_Output is

      procedure PS (Text : VSS.Strings.Virtual_String);

      procedure PL (Text : VSS.Strings.Virtual_String);

      procedure NL;

   end Generic_Output;

end RTG.Utilities;
