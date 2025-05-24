--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Text_IO;

with VSS.Characters;
with VSS.JSON.Content_Handlers;
with VSS.JSON.Push_Readers.Simple;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Input;

with RTG.Diagnostics;
with RTG.Utilities;

package body RTG.GNAT_RTS_Sources is

   type States is
     (Initial,
      Library,
      Library_Description,
      Library_Sources,
      Library_Source_Directories);

   type Condition is record
      Name  : VSS.Strings.Virtual_String;
      Value : VSS.Strings.Virtual_String;
   end record;

   package Condition_Vectors is
     new Ada.Containers.Vectors (Positive, Condition);

   --  package Directory_Vectors is
   --    new Ada.Containers.Vectors (Positive, GNATCOLL.VFS.Virtual_File);

   type Copy_Handler is
     new VSS.JSON.Content_Handlers.JSON_Content_Handler with record
      Scenarios         : Scenario_Maps.Map;
      Base_Directory    : GNATCOLL.VFS.Virtual_File;
      Runtime_Directory : GNATCOLL.VFS.Virtual_File;
      Tasking_Directory : GNATCOLL.VFS.Virtual_File;

      State             : States := Initial;
      Ignore_Value      : Boolean := False;
      Ignore_Object     : Natural := 0;
      Ignore_Array      : Natural := 0;
      Sources_Depth     : Natural := 0;
      Conditions        : Condition_Vectors.Vector;
      Target_Directory  : GNATCOLL.VFS.Virtual_File;
   end record;

   --  procedure Start_Document
   --    (Self : in out Copy_Handler; Success : in out Boolean) is null;
   --  --  Called when processing of JSON document has been started
   --
   --  procedure End_Document
   --    (Self : in out JSON_Content_Handler; Success : in out Boolean);

   overriding procedure Start_Array
     (Self : in out Copy_Handler; Success : in out Boolean);

   overriding procedure End_Array
     (Self : in out Copy_Handler; Success : in out Boolean);

   overriding procedure Start_Object
     (Self : in out Copy_Handler; Success : in out Boolean);

   overriding procedure End_Object
     (Self : in out Copy_Handler; Success : in out Boolean);

   overriding procedure Key_Name
     (Self    : in out Copy_Handler;
      Name    : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean);

   overriding procedure String_Value
     (Self    : in out Copy_Handler;
      Value   : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean);

   overriding procedure Number_Value
     (Self    : in out Copy_Handler;
      Value   : VSS.JSON.JSON_Number;
      Success : in out Boolean);

   overriding procedure Boolean_Value
     (Self    : in out Copy_Handler;
      Value   : Boolean;
      Success : in out Boolean);

   overriding procedure Null_Value
     (Self : in out Copy_Handler; Success : in out Boolean);

   overriding function Error_Message
     (Self : Copy_Handler) return VSS.Strings.Virtual_String;

   -------------------
   -- Boolean_Value --
   -------------------

   overriding procedure Boolean_Value
     (Self    : in out Copy_Handler;
      Value   : Boolean;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Value then
         Self.Ignore_Value := False;

         return;
      end if;

      if Self.Ignore_Array /= 0 or Self.Ignore_Object /= 0 then
         raise Program_Error;
         --  return;
      end if;

      raise Program_Error;
   end Boolean_Value;

   ----------
   -- Copy --
   ----------

   procedure Copy
     (Descriptor  : RTG.Runtime.Runtime_Descriptor'Class;
      Scenarios   : Scenario_Maps.Map;
      RTS_Sources : GNATCOLL.VFS.Virtual_File)
   is
      Input   : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader  : VSS.JSON.Push_Readers.Simple.JSON_Simple_Push_Reader;
      Handler : aliased Copy_Handler;

   begin
      Handler.Scenarios         := Scenarios;
      Handler.Base_Directory    := RTS_Sources.Dir;
      Handler.Runtime_Directory := Descriptor.Runtime_Source_Directory;
      Handler.Tasking_Directory := Descriptor.Tasking_Source_Directory;

      Input.Open
        (VSS.Strings.Conversions.To_Virtual_String
           (RTS_Sources.Display_Full_Name));
      Reader.Set_Stream (Input'Unchecked_Access);
      Reader.Set_Content_Handler (Handler'Unchecked_Access);

      Reader.Parse;

      Input.Close;
   end Copy;

   ---------------
   -- End_Array --
   ---------------

   overriding procedure End_Array
     (Self : in out Copy_Handler; Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Array /= 0 then
         Self.Ignore_Array := @ - 1;

         return;
      end if;

      case Self.State is
         when Initial =>
            raise Program_Error;

         when Library =>
            raise Program_Error;

         when Library_Description =>
            raise Program_Error;

         when Library_Sources =>
            raise Program_Error;

         when Library_Source_Directories =>
            Self.State := Library_Sources;
      end case;
   end End_Array;

   ----------------
   -- End_Object --
   ----------------

   overriding procedure End_Object
     (Self : in out Copy_Handler; Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Object /= 0 then
         Self.Ignore_Object := @ - 1;

         return;
      end if;

      case Self.State is
         when Initial =>
            raise Program_Error;

         when Library =>
            Self.State := Initial;

         when Library_Description =>
            Self.State := Library;

         when Library_Sources =>
            Self.Conditions.Delete_Last;
            Self.Sources_Depth := @ - 1;

            if Self.Sources_Depth = 0 then
               Self.State := Library_Description;
            end if;

         when Library_Source_Directories =>
            raise Program_Error;
      end case;
   end End_Object;

   -------------------
   -- Error_Message --
   -------------------

   overriding function Error_Message
     (Self : Copy_Handler) return VSS.Strings.Virtual_String is
   begin
      return VSS.Strings.Empty_Virtual_String;
   end Error_Message;

   --------------
   -- Key_Name --
   --------------

   overriding procedure Key_Name
     (Self    : in out Copy_Handler;
      Name    : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

      use VSS.Strings;
      --  use type VSS.Strings.Virtual_String;

      Key : VSS.Strings.Virtual_String
        renames VSS.Strings.Virtual_String (Name);

   begin
      if Self.Ignore_Object /= 0 then
         --  Self.Ignore_Object := @ + 1;
         --  Self.Ignore_Value  := True;
         --
         return;
      end if;

      case Self.State is
         when Initial =>
            raise Program_Error;

         when Library =>
            if Key = "gnarl" then
               Self.Ignore_Value := True;

            elsif Key = "gnat" then
               Self.Target_Directory := Self.Runtime_Directory;

            elsif Key = "version" then
               Self.Ignore_Value := True;

            else
               RTG.Diagnostics.Error ("unknown library");
            end if;

         when Library_Description =>
            if Key = "scenarios" then
               Self.Ignore_Value := True;

            elsif Key = "sources" then
               Self.State := Library_Sources;

            else
               raise Program_Error;
            end if;

         when Library_Sources =>
            if Key = "_srcs" then
               for Condition of Self.Conditions loop
                  if Self.Scenarios.Contains (Condition.Name) then
                     if Self.Scenarios (Condition.Name) /= Condition.Value then
                        Self.Ignore_Value := True;

                        return;
                     end if;

                  else
                     RTG.Diagnostics.Warning
                       ("GNAT RTS sources scenaio ""{}"" is not defined",
                        Condition.Name);

                     Self.Ignore_Value := True;

                     return;
                  end if;
               end loop;

               Self.State := Library_Source_Directories;

            else
               declare
                  use type VSS.Characters.Virtual_Character;

                  Iterator  :
                    VSS.Strings.Character_Iterators.Character_Iterator :=
                      Key.Before_First_Character;
                  Character : VSS.Characters.Virtual_Character'Base;

               begin
                  while Iterator.Forward (Character) loop
                     exit when Character = ':';
                  end loop;

                  Self.Conditions.Append
                    (Condition'
                       (Key.Head_Before (Iterator),
                        Key.Tail_After (Iterator)));
               end;
            end if;

         when Library_Source_Directories =>
            raise Program_Error;
      end case;
   end Key_Name;

   ----------------
   -- Null_Value --
   ----------------

   overriding procedure Null_Value
     (Self : in out Copy_Handler; Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Value then
         Self.Ignore_Value := False;

         return;
      end if;

      if Self.Ignore_Array /= 0 or Self.Ignore_Object /= 0 then
         return;
      end if;

      raise Program_Error;
   end Null_Value;

   ------------------
   -- Number_Value --
   ------------------

   overriding procedure Number_Value
     (Self    : in out Copy_Handler;
      Value   : VSS.JSON.JSON_Number;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Value then
         Self.Ignore_Value := False;

         return;
      end if;

      if Self.Ignore_Array /= 0 or Self.Ignore_Object /= 0 then
         return;
      end if;

      raise Program_Error;
   end Number_Value;

   -----------------
   -- Start_Array --
   -----------------

   overriding procedure Start_Array
     (Self : in out Copy_Handler; Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Value then
         Self.Ignore_Value := False;
         Self.Ignore_Array := @ + 1;

         return;
      end if;

      if Self.Ignore_Array /= 0 or Self.Ignore_Object /= 0 then
         Self.Ignore_Array := @ + 1;

         return;
      end if;

      case Self.State is
         when Initial =>
            raise Program_Error;

         when Library =>
            raise Program_Error;

         when Library_Description =>
            raise Program_Error;

         when Library_Sources =>
            raise Program_Error;

         when Library_Source_Directories =>
            null;
      end case;
   end Start_Array;

   ------------------
   -- Start_Object --
   ------------------

   overriding procedure Start_Object
     (Self : in out Copy_Handler; Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Value then
         Self.Ignore_Value := False;
         Self.Ignore_Object := @ + 1;

         return;
      end if;

      if Self.Ignore_Array /= 0 or Self.Ignore_Object /= 0 then
         Self.Ignore_Object := @ + 1;

         return;
      end if;

      case Self.State is
         when Initial =>
            Self.State := Library;

         when Library =>
            Self.State := Library_Description;

         when Library_Description =>
            raise Program_Error;

         when Library_Sources =>
            Self.Sources_Depth := @ + 1;

         when Library_Source_Directories =>
            raise Program_Error;
      end case;
   end Start_Object;

   ------------------
   -- String_Value --
   ------------------

   overriding procedure String_Value
     (Self    : in out Copy_Handler;
      Value   : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      if Self.Ignore_Value then
         Self.Ignore_Value := False;

         return;
      end if;

      if Self.Ignore_Array /= 0 or Self.Ignore_Object /= 0 then
         return;
      end if;

      case Self.State is
         when Initial =>
            raise Program_Error;

         when Library =>
            raise Program_Error;

         when Library_Description =>
            raise Program_Error;

         when Library_Sources =>
            raise Program_Error;

         when Library_Source_Directories =>
            declare
               Source_Directory : constant GNATCOLL.VFS.Virtual_File :=
                 GNATCOLL.VFS.Create_From_Base
                   (GNATCOLL.VFS.Filesystem_String
                      (VSS.Strings.Conversions.To_UTF_8_String (Value)),
                    Self.Base_Directory.Full_Name.all);

            begin
               Ada.Text_IO.Put_Line (Source_Directory.Display_Full_Name);
               RTG.Utilities.Copy_Files
                 (Source_Directory, Self.Target_Directory);
            end;
      end case;
   end String_Value;

end RTG.GNAT_RTS_Sources;
