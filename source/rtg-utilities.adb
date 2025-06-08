--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.Diagnostics;

package body RTG.Utilities is

   use GNATCOLL.VFS;

   ----------------
   -- Copy_Files --
   ----------------

   procedure Copy_Files
     (Source_Directory : GNATCOLL.VFS.Virtual_File;
      Target_Directory : GNATCOLL.VFS.Virtual_File) is
   begin
      if not Source_Directory.Is_Directory then
         RTG.Diagnostics.Error (Source_Directory, "is not a directory");
      end if;

      if not Target_Directory.Is_Directory then
         RTG.Diagnostics.Error (Target_Directory, "is not a directory");
      end if;

      declare
         Iterator : Virtual_Dir := Source_Directory.Open_Dir;
         Source   : Virtual_File;
         Target   : Virtual_File;
         Success  : Boolean;

      begin
         loop
            Read (Iterator, Source);

            exit when Source = No_File;

            if Source.Is_Regular_File then
               Target := Target_Directory.Create_From_Dir (Source.Base_Name);

               if Target.Is_Regular_File then
                  RTG.Diagnostics.Warning (Target, "is overwritten");
               end if;

               Source.Copy (Target.Full_Name.all, Success);

               if not Success then
                  RTG.Diagnostics.Error (Target, "unable to copy file");
               end if;
            end if;
         end loop;
      end;
   end Copy_Files;

end RTG.Utilities;
