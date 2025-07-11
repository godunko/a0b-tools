--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.JSON.Pull_Readers.JSON5;
with VSS.JSON.Streams;
with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Input;

with RTG.Diagnostics;

package body RTG.Startup.Reader is

   ----------
   -- Read --
   ----------

   procedure Read
     (File      : GNATCOLL.VFS.Virtual_File;
      Startup   : in out RTG.Startup.Startup_Descriptor;
      Scenarios : RTG.Scenario_Maps.Map)
   is
      use all type VSS.JSON.Streams.JSON_Stream_Element_Kind;
      use type VSS.Strings.Virtual_String;

      Input  : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader : VSS.JSON.Pull_Readers.JSON5.JSON5_Pull_Reader;

      procedure Read_Configuration
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Read_Parameters
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      ------------------------
      -- Read_Configuration --
      ------------------------

      procedure Read_Configuration is
         type Configuration_Parameters is
           (Unknown, Project, Unit, Subprogram, Parameters);

         Key       : VSS.Strings.Virtual_String;
         Parameter : Configuration_Parameters := Unknown;

      begin
         loop
            case Reader.Read_Next is
               when End_Object =>
                  exit;

               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "project" then
                     Parameter := Project;

                  elsif Key = "unit" then
                     Parameter := Unit;

                  elsif Key = "subprogram" then
                     Parameter := Subprogram;

                  elsif Key = "parameters" then
                     Parameter := Parameters;

                  else
                     Parameter := Unknown;
                     RTG.Diagnostics.Warning
                       ("unknown configuration parameter `{}`", Key);
                  end if;

               when String_Value =>
                  case Parameter is
                     when Unknown =>
                        null;

                     when Project =>
                        Startup.Project_File_Name := Reader.String_Value;

                     when Unit =>
                        Startup.Compilation_Unit := Reader.String_Value;

                     when Subprogram =>
                        Startup.Generic_Subprogram := Reader.String_Value;

                     when others =>
                        RTG.Diagnostics.Warning
                          ("configuration parameter `{}` is not a string",
                           Key);
                  end case;

               when Start_Object =>
                  case Parameter is
                     when Parameters =>
                        Read_Parameters;

                     when others =>
                        Reader.Skip_Current_Object;
                        RTG.Diagnostics.Warning
                          ("configuration parameter `{}` is not an object",
                           Key);
                  end case;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Configuration;

      ---------------------
      -- Read_Parameters --
      ---------------------

      procedure Read_Parameters is
         Key   : VSS.Strings.Virtual_String;
         Name  : VSS.Strings.Virtual_String;
         Value : VSS.Strings.Virtual_String;

      begin
         loop
            case Reader.Read_Next is
               when End_Object =>
                  exit;

               when Key_Name =>
                  Key := Reader.Key_Name;

               when String_Value =>
                  Name := Reader.String_Value;

                  if Scenarios.Contains (Name) then
                     Value := Scenarios (Name);

                  else
                     RTG.Diagnostics.Error
                       ("device tree path `{}` is not found", Name);
                  end if;

                  Startup.Parameters.Append ((Key, Name, Value));

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Parameters;

   begin
      Input.Open
        (VSS.Strings.Conversions.To_Virtual_String (File.Display_Full_Name));
      Reader.Set_Stream (Input'Unchecked_Access);

      loop
         case Reader.Read_Next is
            when Start_Document =>
               null;

            when End_Document =>
               exit;

            when Start_Object =>
               Read_Configuration;

            when others =>
               raise Program_Error with Reader.Element_Kind'Img;
         end case;
      end loop;

      Input.Close;
   end Read;

end RTG.Startup.Reader;
