--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Ada.Containers.Vectors;
with Ada.Text_IO;

with VSS.Characters;
with VSS.JSON.Pull_Readers.Simple;
with VSS.JSON.Streams;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Input;

with RTG.Diagnostics;
with RTG.Tasking;
with RTG.Utilities;

package body RTG.GNAT_RTS_Sources is

   type Condition is record
      Name  : VSS.Strings.Virtual_String;
      Value : VSS.Strings.Virtual_String;
   end record;

   package Condition_Vectors is
     new Ada.Containers.Vectors (Positive, Condition);

   ----------
   -- Copy --
   ----------

   procedure Copy
     (Runtime     : RTG.Runtime.Runtime_Descriptor'Class;
      Tasking     : RTG.Tasking.Tasking_Descriptor;
      Scenarios   : RTG.Scenario_Maps.Map;
      RTS_Sources : GNATCOLL.VFS.Virtual_File)
   is
      use all type VSS.JSON.Streams.JSON_Stream_Element_Kind;
      use type VSS.Strings.Virtual_String;

      Input  : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader : VSS.JSON.Pull_Readers.Simple.JSON_Simple_Pull_Reader;

      Target_Directory : GNATCOLL.VFS.Virtual_File;

      procedure Read_Root_Object
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Read_Library
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Read_Sources
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Skip_Current_Array
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Skip_Current_Object
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      ------------------------
      -- Skip_Current_Array --
      ------------------------

      procedure Skip_Current_Array is
      begin
         loop
            case Reader.Read_Next is
               when End_Array =>
                  exit;

               when String_Value =>
                  null;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Skip_Current_Array;

      -------------------------
      -- Skip_Current_Object --
      -------------------------

      procedure Skip_Current_Object is
      begin
         loop
            case Reader.Read_Next is
               when End_Object =>
                  exit;

               when Key_Name =>
                  null;

               when Start_Array =>
                  Skip_Current_Array;

               when Start_Object =>
                  Skip_Current_Object;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Skip_Current_Object;

      ------------------
      -- Read_Sources --
      ------------------

      procedure Read_Sources is
         type Components is (Srcs);

         Key        : VSS.Strings.Virtual_String;
         Component  : Components;
         Conditions : Condition_Vectors.Vector;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "_srcs" then
                     Component := Srcs;

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

                        Conditions.Append
                          (Condition'
                             (Key.Head_Before (Iterator),
                              Key.Tail_After (Iterator)));
                     end;
                  end if;

               when Start_Object =>
                  null;

               when End_Object =>
                  exit when Conditions.Is_Empty;

                  Conditions.Delete_Last;

               when Start_Array =>
                  case Component is
                     when Srcs =>
                        for Condition of Conditions loop
                           if Scenarios.Contains (Condition.Name) then
                              if Scenarios (Condition.Name) /= Condition.Value
                              then
                                 Skip_Current_Array;

                                 exit;
                              end if;

                           else
                              RTG.Diagnostics.Warning
                                ("GNAT RTS sources scenaio ""{}"" is not defined",
                                 Condition.Name);

                              Skip_Current_Array;

                              exit;
                           end if;
                        end loop;

                     when others =>
                        raise Program_Error;
                  end case;

               when End_Array =>
                  null;

               when String_Value =>
                  case Component is
                     when Srcs =>
                        declare
                           Source_Directory : constant
                             GNATCOLL.VFS.Virtual_File :=
                               GNATCOLL.VFS.Create_From_Base
                                 (GNATCOLL.VFS.Filesystem_String
                                    (VSS.Strings.Conversions.To_UTF_8_String
                                       (Reader.String_Value)),
                                  RTS_Sources.Dir_Name);

                        begin
                           Ada.Text_IO.Put_Line (Source_Directory.Display_Full_Name);
                           RTG.Utilities.Copy_Files
                             (Source_Directory, Target_Directory);
                        end;

                     when others =>
                        raise Program_Error;
                  end case;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Sources;

      ------------------
      -- Read_Library --
      ------------------

      procedure Read_Library is
         type Components is (Unknown, Scenarios, Sources);

         Key       : VSS.Strings.Virtual_String;
         Component : Components := Unknown;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "scenarios" then
                     Component := Scenarios;

                  elsif Key = "sources" then
                     Component := Sources;

                  else
                     raise Program_Error;
                  end if;

               when Start_Object =>
                  case Component is
                     when Scenarios =>
                        Skip_Current_Object;

                     when Sources =>
                        Read_Sources;

                     when others =>
                        raise Program_Error;
                  end case;

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Library;

      ----------------------
      -- Read_Root_Object --
      ----------------------

      procedure Read_Root_Object is
         type Components is (Unknown, Library, Version);

         Key       : VSS.Strings.Virtual_String;
         Component : Components := Unknown;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "gnarl" then
                     if RTG.Tasking.Use_GNAT_Tasking (Tasking) then
                        Component        := Library;
                        Target_Directory :=
                          Runtime.Aux_Tasking_Source_Directory;

                     else
                        Component := Unknown;
                     end if;

                  elsif Key = "gnat" then
                     Component        := Library;
                     Target_Directory := Runtime.Aux_Runtime_Source_Directory;

                  elsif Key = "version" then
                     Component := Version;

                  else
                     RTG.Diagnostics.Error ("unknown library");
                  end if;

               when Start_Object =>
                  case Component is
                     when Unknown =>
                        Skip_Current_Object;

                     when Library =>
                        Read_Library;

                     when others =>
                        raise Program_Error;
                  end case;

               when String_Value =>
                  case Component is
                     when Version =>
                        null;

                     when others =>
                        raise Program_Error;
                  end case;

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Root_Object;

   begin
      Reader.Set_Stream (Input'Unchecked_Access);

      Input.Open
        (VSS.Strings.Conversions.To_Virtual_String
           (RTS_Sources.Display_Full_Name));

      loop
         case Reader.Read_Next is
            when Start_Document =>
               null;

            when Start_Object =>
               Read_Root_Object;

            when End_Document =>
               exit;

            when others =>
               raise Program_Error with Reader.Element_Kind'Img;
         end case;
      end loop;

      Input.Close;
   end Copy;

end RTG.GNAT_RTS_Sources;
