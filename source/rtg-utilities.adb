--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Output;

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

   ---------------
   -- Copy_File --
   ---------------

   procedure Copy_File
     (Source_Base      : GNATCOLL.VFS.Virtual_File;
      Source_Path      : VSS.Strings.Virtual_String;
      Target_Directory : GNATCOLL.VFS.Virtual_File;
      Target_Name      : VSS.Strings.Virtual_String)
   is
      Success : Boolean;
      Source  : GNATCOLL.VFS.Virtual_File;
      Target  : GNATCOLL.VFS.Virtual_File;

   begin
      Source :=
        GNATCOLL.VFS.Create_From_Dir
          (Source_Base,
           GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String (Source_Path)));
      Target :=
        GNATCOLL.VFS.Create_From_Dir
          (Target_Directory,
           GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String (Target_Name)));

      Source.Copy (Target.Full_Name.all, Success);

      if not Success then
         RTG.Diagnostics.Error (Target, "unable to copy file");
      end if;
   end Copy_File;

   --------------------
   -- Generic_Output --
   --------------------

   package body Generic_Output is

      Output  : VSS.Text_Streams.File_Output.File_Output_Text_Stream;
      Success : Boolean := True;

      --------
      -- NL --
      --------

      procedure NL is
      begin
         Output.New_Line (Success);
      end NL;

      --------
      -- PL --
      --------

      procedure PL (Text : VSS.Strings.Virtual_String) is
      begin
         Output.Put_Line (Text, Success);
      end PL;

      --------
      -- PS --
      --------

      procedure PS (Text : VSS.Strings.Virtual_String) is
      begin
         Output.Put (Text, Success);
      end PS;

   begin
      declare
         File : constant GNATCOLL.VFS.Virtual_File :=
           Directory.Create_From_Dir
             (GNATCOLL.VFS.Filesystem_String
                (VSS.Strings.Conversions.To_UTF_8_String (File_Name)));

      begin
         if File.Is_Regular_File then
            RTG.Diagnostics.Warning (File, "is overwritten");
         end if;

         Output.Create
           (VSS.Strings.Conversions.To_Virtual_String
              (File.Display_Full_Name));
      end;
   end Generic_Output;

end RTG.Utilities;
